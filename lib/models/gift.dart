class Gift {
  static const _imagePrefix = "assets/images";
  static const all = [
    Gift(
      name: "奶茶",
      quantifier: "杯",
      verb: "喝",
      des: "你爱我，我爱你...",
      imagePath: "$_imagePrefix/milktea.webp",
      price: 600,
    ),
    Gift(
      name: "三明治",
      quantifier: "份",
      verb: "吃",
      des: "煎蛋火腿生菜三兄弟",
      imagePath: "$_imagePrefix/sandwich.webp",
      price: 1200,
    ),
    Gift(
      name: "寿司",
      quantifier: "份",
      verb: "吃",
      des: "回转寿司转圈圈",
      imagePath: "$_imagePrefix/sushi.webp",
      price: 2000,
    ),
    Gift(
      name: "鸡汤面",
      quantifier: "碗",
      verb: "吃",
      des: "开启无限续面模式",
      imagePath: "$_imagePrefix/noodles.webp",
      price: 3800,
    ),
    Gift(
      name: "牛排",
      quantifier: "块",
      verb: "吃",
      des: "自己在家做比店里便宜很多哦",
      imagePath: "$_imagePrefix/steak.webp",
      price: 5900,
    ),
    Gift(
      name: "松鼠鱼",
      quantifier: "条",
      verb: "吃",
      des: "正如老婆饼里没有老婆...",
      imagePath: "$_imagePrefix/fish.webp",
      price: 10800,
    ),
  ];
  final String name;
  final String quantifier;
  final String verb;
  final String des;
  final String imagePath;
  final int price;

  const Gift({
    required this.name,
    required this.quantifier,
    required this.verb,
    required this.des,
    required this.imagePath,
    required this.price,
  });
}
