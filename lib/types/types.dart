import 'package:sauraya/types/ollama.dart';

typedef Messages = List<Message>;

class Message {
  final String role;
  final String content;
  final List<String>? images;
  final List<String>? videos;
  final String? msgId;
  final String? code;
  final String? pdfContent;

  Message({
    required this.role,
    required this.content,
    this.images,
    this.videos,
    this.msgId,
    this.code,
    this.pdfContent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      videos: json['videos'] != null ? List<String>.from(json['videos']) : null,
      msgId: json['msgId'],
      code: json['code'],
      pdfContent: json['pdfContent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'images': images,
      'videos': videos,
      'msgId': msgId,
      'code': code,
      'pdfContent': pdfContent,
    };
  }
}

class OllamaChatRequest {
  final String model;
  final Messages messages;
  final bool? stream;
  final String? token;
  final List<Tool>? tools;
  final bool? isWebSearch;

  OllamaChatRequest({
    required this.model,
    required this.messages,
    this.stream,
    this.token,
    this.tools,
    this.isWebSearch,
  });

  factory OllamaChatRequest.fromJson(Map<String, dynamic> json) {
    return OllamaChatRequest(
      model: json['model'],
      messages:
          (json['messages'] as List).map((e) => Message.fromJson(e)).toList(),
      stream: json['stream'],
      token: json['token'],
      tools: (json['tools'] as List).map((e) => Tool.fromJson(e)).toList(),
      isWebSearch: json['isWebSearch'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map((e) => e.toJson()).toList(),
      'stream': stream,
      'token': token,
      'tools': tools?.map((e) => e.toJson()).toList(),
      'isWebSearch': isWebSearch,
    };
  }
}

class PartialResponse {
  final bool isFirst;
  final ChatResponse response;

  PartialResponse({
    required this.isFirst,
    required this.response,
  });

  factory PartialResponse.fromJson(Map<String, dynamic> json) {
    return PartialResponse(
      isFirst: json['isFirst'],
      response: ChatResponse.fromJson(json['response']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFirst': isFirst,
      'response': response.toJson(),
    };
  }
}

class ChatResponse {
  final String model;
  final DateTime createdAt;
  final Message message;
  final bool done;
  final String doneReason;
  final double totalDuration;
  final double loadDuration;
  final int promptEvalCount;
  final double promptEvalDuration;
  final int evalCount;
  final double evalDuration;

  ChatResponse({
    required this.model,
    required this.createdAt,
    required this.message,
    required this.done,
    required this.doneReason,
    required this.totalDuration,
    required this.loadDuration,
    required this.promptEvalCount,
    required this.promptEvalDuration,
    required this.evalCount,
    required this.evalDuration,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      model: json['model'],
      createdAt: DateTime.parse(json['created_at']),
      message: Message.fromJson(json['message']),
      done: json['done'],
      doneReason: json['done_reason'],
      totalDuration: json['total_duration'].toDouble(),
      loadDuration: json['load_duration'].toDouble(),
      promptEvalCount: json['prompt_eval_count'],
      promptEvalDuration: json['prompt_eval_duration'].toDouble(),
      evalCount: json['eval_count'],
      evalDuration: json['eval_duration'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'created_at': createdAt.toIso8601String(),
      'message': message.toJson(),
      'done': done,
      'done_reason': doneReason,
      'total_duration': totalDuration,
      'load_duration': loadDuration,
      'prompt_eval_count': promptEvalCount,
      'prompt_eval_duration': promptEvalDuration,
      'eval_count': evalCount,
      'eval_duration': evalDuration,
    };
  }
}

class Conversation {
  final String title;
  final String id;
  final List<Message> messages;

  Conversation({
    required this.title,
    required this.messages,
    required this.id,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      title: json['title'],
      id: json['id'],
      messages: (json['messages'] as List)
          .map((message) => Message.fromJson(message))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'id': id,
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }
}

typedef ConversationsInterface = Map<String, Map<String, Conversation>>;

class Conversations {
  final Map<String, Conversation> conversations;

  Conversations({required this.conversations});

  factory Conversations.fromJson(Map<String, dynamic> json) {
    return Conversations(
      conversations: json.map(
        (key, value) => MapEntry(
          key,
          Conversation.fromJson(value),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return conversations.map(
      (key, value) => MapEntry(
        key,
        value.toJson(),
      ),
    );
  }
}

class UserData {
  final String name;
  final String userId;
  final int joiningDate;
  final String address;
  final String token;

  // Constructeur de la classe
  UserData({
    required this.name,
    required this.userId,
    required this.joiningDate,
    required this.address,
    required this.token,
  });

  // Méthode pour convertir un objet JSON en une instance de UserData
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] as String,
      userId: json['userId'] as String,
      joiningDate: json['joiningDate'] as int,
      address: json['address'] as String,
      token: json['token'] as String,
    );
  }

  // Méthode pour convertir une instance de UserData en un objet JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'userId': userId,
      'joiningDate': joiningDate,
      'address': address,
      'token': token,
    };
  }
}
