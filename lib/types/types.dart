typedef Messages = List<Message>;

class Message {
  final String role;
  final String content;
  final List<String>? images;

  Message({
    required this.role,
    required this.content,
    this.images,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'images': images,
    };
  }
}

class OllamaChatRequest {
  final String model;
  final Messages messages;
  final bool? stream;

  OllamaChatRequest({
    required this.model,
    required this.messages,
    this.stream,
  });

  factory OllamaChatRequest.fromJson(Map<String, dynamic> json) {
    return OllamaChatRequest(
      model: json['model'],
      messages:
          (json['messages'] as List).map((e) => Message.fromJson(e)).toList(),
      stream: json['stream'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map((e) => e.toJson()).toList(),
      'stream': stream,
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
