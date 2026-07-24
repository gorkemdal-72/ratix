import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'https://esm.sh/google-auth-library@9'

interface NotificationPayload {
  type: string
  table: string
  record: {
    id: string
    recipient_id: string
    sender_id: string
    type: string
    post_id?: string
    comment_id?: string
    is_read: boolean
    created_at: string
  }
  schema: string
}

serve(async (req) => {
  try {
    // 1. Webhook'tan gelen veriyi al
    const payload: NotificationPayload = await req.json()
    const record = payload.record

    // Sadece yeni eklenen (INSERT) bildirimleri işle
    if (payload.type !== 'INSERT') {
      return new Response('Not an insert event', { status: 200 })
    }

    // 2. Supabase Client oluştur (FCM Token ve Kullanıcı Adı için)
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Alıcının (recipient_id) fcm_token'ını al
    const { data: receiverData, error: receiverError } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', record.recipient_id)
      .single()

    if (receiverError || !receiverData?.fcm_token) {
      console.log('Alıcı bulunamadı veya fcm_token yok.')
      return new Response('No fcm_token', { status: 200 })
    }

    // İşlemi yapanın (sender_id) kullanıcı adını al
    const { data: actorData } = await supabase
      .from('users')
      .select('username')
      .eq('id', record.sender_id)
      .single()

    const actorName = actorData?.username || 'Birisi'
    const fcmToken = receiverData.fcm_token

    let title = 'Yeni Bildirim'
    let body = ''

    // 3.5. İlişkili verileri çek (post/item veya comment)
    let itemTitle = ''
    let commentText = ''
    
    if (record.post_id) {
      const { data: postData } = await supabase
        .from('posts')
        .select('*, items(title)')
        .eq('id', record.post_id)
        .single()
      if (postData?.items?.title) itemTitle = postData.items.title
    }

    if (record.comment_id) {
      const { data: commentData } = await supabase
        .from('comments')
        .select('content')
        .eq('id', record.comment_id)
        .single()
      if (commentData?.content) {
        commentText = commentData.content.length > 30 
          ? commentData.content.substring(0, 30) + '...' 
          : commentData.content
      }
    }

    switch (record.type) {
      case 'post_like':
        title = 'Yeni Beğeni ❤️'
        body = itemTitle ? `${actorName} '${itemTitle}' paylaşımını beğendi.` : `${actorName} gönderini beğendi.`
        break
      case 'comment_like':
        title = 'Yeni Beğeni ❤️'
        body = commentText ? `${actorName} '${commentText}' yorumunu beğendi.` : `${actorName} yorumunu beğendi.`
        break
      case 'comment':
        title = 'Yeni Yorum 💬'
        body = itemTitle ? `${actorName} '${itemTitle}' paylaşımına yorum yaptı.` : `${actorName} gönderine yorum yaptı.`
        break
      case 'reply':
        title = 'Yanıtlama 💬'
        body = commentText ? `${actorName} '${commentText}' yorumuna yanıt verdi.` : `${actorName} yorumuna yanıt verdi.`
        break
      case 'follow':
        title = 'Yeni Takipçi 👤'
        body = `${actorName} seni takip etmeye başladı.`
        break
      case 'new_report':
        title = 'Yeni Şikayet 🚨'
        body = `${actorName} yeni bir şikayet oluşturdu. Moderasyon Paneli'ni kontrol edin.`
        break
      case 'report_resolved':
        title = 'Şikayet Çözüldü ✅'
        body = 'Şikayetin incelendi ve gerekli aksiyon alındı. Teşekkürler!'
        break
      case 'report_dismissed':
        title = 'Şikayet Sonucu ℹ️'
        body = 'Şikayetin incelendi ancak herhangi bir ihlal tespit edilmedi.'
        break
      case 'warning':
        title = 'Uyarı Aldın ⚠️'
        body = 'Moderatörler tarafından hesabına bir uyarı gönderildi.'
        break
      case 'mute':
        title = 'Susturuldun 🔇'
        body = 'Kuralları ihlal ettiğin için geçici olarak susturuldun.'
        break
      case 'ban':
        title = 'Hesabın Yasaklandı 🚫'
        body = 'Kuralları ihlal ettiğin için hesabın kalıcı olarak yasaklandı.'
        break
      default:
        body = `${actorName} seninle etkileşime geçti.`
    }

    // 4. Firebase Kimlik Doğrulaması (Service Account)
    // SUPABASE DASHBOARD > Project Settings > Edge Functions > Secrets kısmına
    // FIREBASE_SERVICE_ACCOUNT adında yeni bir secret eklemelisiniz.
    // İçine Firebase Console'dan indirdiğiniz service account JSON'unu YAPIŞTIRIN.
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT secret is missing!')
    }

    const serviceAccount = JSON.parse(serviceAccountJson)
    
    // JWT Token oluştur
    const client = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    const accessToken = await client.getAccessToken()

    // 5. Firebase HTTP v1 API ile bildirimi gönder
    // Firebase Project ID (google-services.json'daki project_id)
    const projectId = serviceAccount.project_id
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          notification_id: record.id,
          type: record.type,
          post_id: record.post_id || '',
          comment_id: record.comment_id || '',
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'high_importance_channel'
          }
        }
      },
    }

    const fcmResponse = await fetch(fcmEndpoint, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fcmPayload),
    })

    const fcmData = await fcmResponse.json()

    if (!fcmResponse.ok) {
      console.error('FCM Error:', fcmData)
      return new Response(JSON.stringify({ error: fcmData }), { status: 500 })
    }

    return new Response(JSON.stringify({ success: true, messageId: fcmData.name }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Webhook Error:', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
