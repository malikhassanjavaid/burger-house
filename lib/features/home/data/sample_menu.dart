import '../models/menu_item.dart';

const sampleMenu = [
  // Burgers
  MenuItem(id: 'classic-smash', name: 'Classic Smash', description: 'Double beef patty, cheddar, pickles and signature house sauce', category: 'Burgers', emoji: '\u{1F354}', assetPath: 'assets/images/beefburger.png', price: 7.49, rating: 4.9, isPopular: true, isRecommended: true),
  MenuItem(id: 'firehouse', name: 'Firehouse Burger', description: 'Flame-grilled beef, melted cheese, crisp vegetables and smoky sauce', category: 'Burgers', emoji: '\u{1F354}', assetPath: 'assets/images/firehouse_burger.png', price: 8.49, oldPrice: 9.49, rating: 4.8, isPopular: true, isDeal: true),
  MenuItem(id: 'chicken-burger', name: 'Crispy Chicken Burger', description: 'Crunchy chicken fillet, cheddar, lettuce and creamy pepper sauce', category: 'Burgers', emoji: '\u{1F354}', assetPath: 'assets/images/chicken_burger-cutout.png', price: 6.49, rating: 4.8, isRecommended: true),
  MenuItem(id: 'fish-burger', name: 'Crispy Fish Burger', description: 'Golden fish fillet, lettuce, cheddar and tangy tartar sauce', category: 'Burgers', emoji: '\u{1F354}', assetPath: 'assets/images/fish_burger-cutout.png', price: 6.79, rating: 4.7, isRecommended: true),
  MenuItem(id: 'cheese-burger', name: 'Ultimate Cheeseburger', description: 'Juicy beef patty layered with rich melted cheese and classic toppings', category: 'Burgers', emoji: '\u{1F354}', assetPath: 'assets/images/cheese_burger.png', price: 7.99, rating: 4.8),
  MenuItem(id: 'grilled-burger', name: 'Chargrilled Burger', description: 'Grilled beef, caramelized flavor, fresh salad and burger sauce', category: 'Burgers', emoji: '\u{1F354}', assetPath: 'assets/images/grilled_burger.png', price: 7.79, rating: 4.7),
  MenuItem(id: 'krunch-burger', name: 'Krunch Burger', description: 'Extra-crispy chicken, creamy slaw and spicy mayo in a toasted bun', category: 'Burgers', emoji: '\u{1F354}', assetPath: 'assets/images/krunch_burger.png', price: 6.99, rating: 4.8, isPopular: true),

  // Pizzas
  MenuItem(id: 'cheese-pizza', name: 'Classic Cheese Pizza', description: 'Stone-baked crust topped with tomato sauce and melted mozzarella', category: 'Pizzas', emoji: '\u{1F355}', assetPath: 'assets/images/cheese_pizza.png', price: 10.99, rating: 4.7, isRecommended: true),
  MenuItem(id: 'pepperoni-pizza', name: 'Pepperoni Pizza', description: 'Mozzarella, rich tomato sauce and generous pepperoni slices', category: 'Pizzas', emoji: '\u{1F355}', assetPath: 'assets/images/pepperoni_pizza.png', price: 12.49, rating: 4.8, isPopular: true),
  MenuItem(id: 'fajita-pizza', name: 'Chicken Fajita Pizza', description: 'Seasoned chicken, peppers, onions and mozzarella with fajita sauce', category: 'Pizzas', emoji: '\u{1F355}', assetPath: 'assets/images/chicked_fajita_pizza.png', price: 12.99, rating: 4.8),
  MenuItem(id: 'kabab-pizza', name: 'Kabab Crown Pizza', description: 'Spiced kabab, onions, peppers and cheese on a savory pizza base', category: 'Pizzas', emoji: '\u{1F355}', assetPath: 'assets/images/kabab_pizza.png', price: 13.49, rating: 4.7),
  MenuItem(id: 'superduper-pizza', name: 'Super Duper Pizza', description: 'A fully loaded combination of chicken, vegetables, olives and cheese', category: 'Pizzas', emoji: '\u{1F355}', assetPath: 'assets/images/superduper_pizza.png', price: 14.49, rating: 4.9, isPopular: true),
  MenuItem(id: 'chef-special-pizza', name: "Chef's Special Pizza", description: 'The chef’s premium combination of seasoned meat, vegetables and mozzarella', category: 'Pizzas', emoji: '\u{1F355}', assetPath: 'assets/images/chefspecial_pizza.png', price: 14.99, rating: 4.9, isRecommended: true),

  // Wraps
  MenuItem(id: 'chicken-wrap', name: 'Crispy Chicken Wrap', description: 'Crispy chicken, lettuce, tomato and garlic mayo wrapped fresh', category: 'Wraps', emoji: '\u{1F32F}', assetPath: 'assets/images/chicken_wrap.png', price: 5.99, rating: 4.7, isRecommended: true),
  MenuItem(id: 'beef-wrap', name: 'Smoky Beef Wrap', description: 'Tender seasoned beef, crunchy vegetables and smoky house dressing', category: 'Wraps', emoji: '\u{1F32F}', assetPath: 'assets/images/beef_wrap.png', price: 6.49, rating: 4.8),

  // Chicken and sides
  MenuItem(id: 'spicy-wings', name: 'Spicy Glazed Wings', description: 'Juicy wings tossed in a sticky sweet-and-spicy glaze', category: 'Chicken', emoji: '\u{1F357}', assetPath: 'assets/images/Spicy_glazed_wings.png', price: 7.49, rating: 4.9, isPopular: true),
  MenuItem(id: 'crispy-wings', name: 'Crispy Chicken Wings', description: 'Golden seasoned wings fried until perfectly crunchy', category: 'Chicken', emoji: '\u{1F357}', assetPath: 'assets/images/crispy_wings.png', price: 6.99, rating: 4.7),
  MenuItem(id: 'chicken-bites', name: 'Chicken Bites', description: 'Tender crunchy chicken bites served with your choice of dip', category: 'Chicken', emoji: '\u{1F357}', assetPath: 'assets/images/chicken_bite.png', price: 5.49, rating: 4.6, isRecommended: true),
  MenuItem(id: 'nuggets', name: 'Golden Nuggets', description: 'Bite-sized chicken nuggets with a crisp golden coating', category: 'Chicken', emoji: '\u{1F357}', assetPath: 'assets/images/nuggets.png', price: 4.99, rating: 4.6),
  MenuItem(id: 'loaded-fries', name: 'Loaded Fries', description: 'Crispy fries loaded with cheese sauce, jalapenos and smoky chicken', category: 'Sides', emoji: '\u{1F35F}', assetPath: 'assets/images/loaded_fries.png', price: 4.99, rating: 4.8, isRecommended: true),
  MenuItem(id: 'fries', name: 'Signature Fries', description: 'Golden, lightly seasoned fries with a crisp finish', category: 'Sides', emoji: '\u{1F35F}', assetPath: 'assets/images/fries.png', price: 2.99, rating: 4.6),

  // Drinks
  MenuItem(id: 'cola', name: 'Classic Cola', description: 'Ice-cold classic cola served chilled', category: 'Drinks', emoji: '\u{1F964}', assetPath: 'assets/images/coke.png', price: 1.49, rating: 4.5),
  MenuItem(id: 'sprite', name: 'Lemon-Lime Sprite', description: 'Refreshing lemon-lime soft drink served chilled', category: 'Drinks', emoji: '\u{1F964}', assetPath: 'assets/images/sprite.png', price: 1.49, rating: 4.5),
  MenuItem(id: 'oreo-shake', name: 'Oreo Shake', description: 'Creamy vanilla shake blended with crunchy Oreo cookies', category: 'Drinks', emoji: '\u{1F964}', assetPath: 'assets/images/oreo_shake.png', price: 4.49, rating: 4.8, isPopular: true),
  MenuItem(id: 'vanilla-frappe', name: 'Vanilla Cloud Frappe', description: 'Smooth vanilla frappe finished with whipped cream', category: 'Drinks', emoji: '\u{1F964}', assetPath: 'assets/images/vanilla_frappe.png', price: 4.29, rating: 4.7),
  MenuItem(id: 'chocolate-frappe', name: 'Chocolate Frappe', description: 'Rich chocolate frappe topped with cream and chocolate drizzle', category: 'Drinks', emoji: '\u{1F964}', assetPath: 'assets/images/chocolate_frappe.png', price: 4.79, rating: 4.8),
  MenuItem(id: 'strawberry-frappe', name: 'Strawberry Frappe', description: 'Creamy strawberry frappe with a fresh berry finish', category: 'Drinks', emoji: '\u{1F964}', assetPath: 'assets/images/strawberry_frappe.png', price: 4.59, rating: 4.7),

  // Desserts
  MenuItem(id: 'brownie', name: 'Fudge Brownie', description: 'Rich chocolate brownie finished with glossy fudge drizzle', category: 'Desserts', emoji: '\u{1F36B}', assetPath: 'assets/images/brownie.png', price: 3.49, rating: 4.8, isRecommended: true),
  MenuItem(id: 'cheesecake', name: 'New York Cheesecake', description: 'Silky baked cheesecake on a buttery biscuit base', category: 'Desserts', emoji: '\u{1F370}', assetPath: 'assets/images/cheesecake_slice.png', price: 4.49, rating: 4.8),
  MenuItem(id: 'loaded-cake', name: 'Loaded Chocolate Cake', description: 'Decadent chocolate cake loaded with cream and chocolate toppings', category: 'Desserts', emoji: '\u{1F370}', assetPath: 'assets/images/loadedcake_slice.png', price: 4.99, rating: 4.9, isPopular: true),
  MenuItem(id: 'tiramisu', name: 'Classic Tiramisu', description: 'Coffee-soaked layers with mascarpone cream and cocoa', category: 'Desserts', emoji: '\u{1F370}', assetPath: 'assets/images/tiramisucake_slice.png', price: 4.79, rating: 4.8),

  // Deals
  MenuItem(id: 'family-box', name: 'Family Feast', description: 'Four signature burgers, two large fries and four chilled drinks', category: 'Deals', emoji: '\u{1F381}', assetPath: 'assets/images/family_feast.png', price: 27.99, oldPrice: 34.99, rating: 4.9, isDeal: true, isRecommended: true),
  MenuItem(id: 'couple-deal', name: 'Duo Deal', description: 'Two premium burgers, a large fries and two chilled drinks', category: 'Deals', emoji: '\u{1F381}', assetPath: 'assets/images/duo_deal.png', price: 14.99, oldPrice: 18.49, rating: 4.8, isDeal: true),
];
