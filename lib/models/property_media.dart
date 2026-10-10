class PropertyMedia {
  const PropertyMedia({required this.url, required this.type});

  final String url;
  final String type;

  factory PropertyMedia.fromJson(Map<String, dynamic> json) => PropertyMedia(
        url: json['url'] as String,
        type: json['type'] as String,
      );

  Map<String, Object> toJson() => {'url': url, 'type': type};
}
