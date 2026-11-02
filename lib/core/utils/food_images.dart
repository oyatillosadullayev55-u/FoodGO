class FoodImages {
  // Ommabop va ishonchli taom rasmlari (Unsplash CDN)
  static const String plov =
      'https://images.unsplash.com/photo-1633964913295-ceb43826e7c9?w=800&auto=format&fit=crop&q=80';
  static const String burger =
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&auto=format&fit=crop&q=80';
  static const String pizza =
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&auto=format&fit=crop&q=80';
  static const String sushi =
      'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800&auto=format&fit=crop&q=80';
  static const String shashlik =
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&auto=format&fit=crop&q=80';
  static const String chicken =
      'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=800&auto=format&fit=crop&q=80';
  static const String coffee =
      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&auto=format&fit=crop&q=80';
  static const String dessert =
      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&auto=format&fit=crop&q=80';
  static const String somsa =
      'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=800&auto=format&fit=crop&q=80';
  static const String salad =
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&auto=format&fit=crop&q=80';
  static const String national =
      'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=800&auto=format&fit=crop&q=80';
  static const String restaurantDefault =
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&auto=format&fit=crop&q=80';

  /// Restoran nomiga qarab haqiqiy mazali rasm tanlaydi
  static String getRestaurantImage(String name, String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty && imageUrl.startsWith('http')) {
      return imageUrl;
    }
    final n = name.toLowerCase();
    if (n.contains('osh') || n.contains('palov') || n.contains('plov')) {
      return plov;
    }
    if (n.contains('burger') || n.contains('fast') || n.contains('lavash') || n.contains('doner')) {
      return burger;
    }
    if (n.contains('pizza') || n.contains('pitsa')) {
      return pizza;
    }
    if (n.contains('sushi') || n.contains('yapona') || n.contains('roll')) {
      return sushi;
    }
    if (n.contains('shashlik') || n.contains('kabob') || n.contains('kebab') || n.contains('go\'sht')) {
      return shashlik;
    }
    if (n.contains('somsa') || n.contains('lagmon') || n.contains('milliy') || n.contains('choyxona')) {
      return somsa;
    }
    if (n.contains('kfc') || n.contains('tovuq') || n.contains('chicken') || n.contains('wings')) {
      return chicken;
    }
    if (n.contains('kofe') || n.contains('coffee') || n.contains('cafe') || n.contains('choy')) {
      return coffee;
    }
    if (n.contains('shirinlik') || n.contains('tort') || n.contains('dessert') || n.contains('cake')) {
      return dessert;
    }
    return restaurantDefault;
  }

  /// Taom nomiga qarab haqiqiy mazali rasm tanlaydi
  static String getProductImage(String name, String? categoryName, String? imageUrl) {
    if (imageUrl != null && imageUrl.trim().isNotEmpty && imageUrl.startsWith('http')) {
      return imageUrl;
    }
    final n = '$name ${categoryName ?? ''}'.toLowerCase();
    if (n.contains('osh') || n.contains('palov') || n.contains('plov')) {
      return plov;
    }
    if (n.contains('burger') || n.contains('cheeseburger')) {
      return burger;
    }
    if (n.contains('lavash') || n.contains('doner') || n.contains('shaurma') || n.contains('hot-dog')) {
      return burger;
    }
    if (n.contains('pizza') || n.contains('pitsa')) {
      return pizza;
    }
    if (n.contains('sushi') || n.contains('roll') || n.contains('set')) {
      return sushi;
    }
    if (n.contains('shashlik') || n.contains('kabob') || n.contains('grill') || n.contains('bifshteks')) {
      return shashlik;
    }
    if (n.contains('somsa') || n.contains('manti') || n.contains('chuchvara')) {
      return somsa;
    }
    if (n.contains('lagmon') || n.contains('sho\'rva') || n.contains('mastava')) {
      return national;
    }
    if (n.contains('tovuq') || n.contains('wings') || n.contains('strips') || n.contains('nuggets')) {
      return chicken;
    }
    if (n.contains('salat') || n.contains('achchiq-chuchuk') || n.contains('sezar')) {
      return salad;
    }
    if (n.contains('kofe') || n.contains('choy') || n.contains('ichimlik') || n.contains('cola') || n.contains('pepsi') || n.contains('fanta') || n.contains('sharbat')) {
      return coffee;
    }
    if (n.contains('tort') || n.contains('pirojnoe') || n.contains('desert') || n.contains('muzqaymoq')) {
      return dessert;
    }
    return national;
  }
}
