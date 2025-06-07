import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String? summary;
  final String source;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String stockId;
  final DateTime createdAt;
  final DateTime updatedAt;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.stockId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        summary: json['summary'] as String?,
        source: json['source'] as String,
        url: json['url'] as String,
        imageUrl: json['imageUrl'] as String?,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        stockId: json['stockId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'summary': summary,
        'source': source,
        'url': url,
        'imageUrl': imageUrl,
        'publishedAt': publishedAt.toIso8601String(),
        'stockId': stockId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

@JsonSerializable()
class NewsResponse {
  final bool success;
  final List<NewsArticle> articles;
  final int totalCount;
  final String? nextPageToken;

  NewsResponse({
    required this.success,
    required this.articles,
    required this.totalCount,
    this.nextPageToken,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) => NewsResponse(
        success: json['success'] as bool,
        articles: (json['articles'] as List)
            .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCount: json['totalCount'] as int,
        nextPageToken: json['nextPageToken'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'articles': articles.map((e) => e.toJson()).toList(),
        'totalCount': totalCount,
        'nextPageToken': nextPageToken,
      };
}

@JsonSerializable()
class NewsFilter {
  final String? stockId;
  final String? source;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;
  final String? nextPageToken;

  NewsFilter({
    this.stockId,
    this.source,
    this.startDate,
    this.endDate,
    this.limit,
    this.nextPageToken,
  });

  Map<String, dynamic> toJson() => {
        'stockId': stockId,
        'source': source,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'limit': limit,
        'nextPageToken': nextPageToken,
      };
}
