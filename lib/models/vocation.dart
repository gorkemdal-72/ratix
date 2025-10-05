enum Vocation{
  warrior(
    title: 'Warrior',
    description: 'A brave fighter skilled in melee combat.',
    image: 'assets/images/warrior.png',
    weapon: 'Sword',
    ability: 'Shield Block',
  )
  , mage(
    title: 'Mage',
    description: 'A master of arcane arts, wielding powerful spells.',
    image: 'assets/images/mage.png',
    weapon: 'Staff',
    ability: 'Fireball',
  )
  , rogue(
    title: 'Rogue',
    description: 'A stealthy assassin, excelling in agility and precision.',
    image: 'assets/images/rogue.png',
    weapon: 'Dagger',
    ability: 'Backstab',
  )
  , archer(
    title: 'Archer',
    description: 'A skilled marksman, deadly from a distance.',
    image: 'assets/images/archer.png',
    weapon: 'Bow',
    ability: 'Piercing Arrow',
  );


  const Vocation({
    required this.title,
    required this.description,
    required this.image,
    required this.weapon,
    required this.ability,
    });

    final String title;
    final String description;
    final String image;
    final String weapon;
    final String ability;
}