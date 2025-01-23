typedef Fetch = Future Function(Uri url, {Map<String, String>? headers});

class Config {
  final String host;
  final Fetch? fetch;
  final bool? proxy;
  final Map<String, String>? headers;

  Config({
    required this.host,
    this.fetch,
    this.proxy,
    this.headers,
  });

  factory Config.fromJson(Map<String, dynamic> json) => Config(
        host: json['host'],
        fetch: json['fetch'],
        proxy: json['proxy'],
        headers: (json['headers'] as Map?)?.cast<String, String>(),
      );

  Map<String, dynamic> toJson() => {
        'host': host,
        'fetch': fetch,
        'proxy': proxy,
        'headers': headers,
      };
}

class Options {
  final bool numa;
  final int numCtx;
  final int numBatch;
  final int numGpu;
  final int mainGpu;
  final bool lowVram;
  final bool f16Kv;
  final bool logitsAll;
  final bool vocabOnly;
  final bool useMmap;
  final bool useMlock;
  final bool embeddingOnly;
  final int numThread;
  final int numKeep;
  final int seed;
  final int numPredict;
  final int topK;
  final double topP;
  final double tfsZ;
  final double typicalP;
  final int repeatLastN;
  final double temperature;
  final double repeatPenalty;
  final double presencePenalty;
  final double frequencyPenalty;
  final int mirostat;
  final double mirostatTau;
  final double mirostatEta;
  final bool penalizeNewline;
  final List<String> stop;

  Options({
    required this.numa,
    required this.numCtx,
    required this.numBatch,
    required this.numGpu,
    required this.mainGpu,
    required this.lowVram,
    required this.f16Kv,
    required this.logitsAll,
    required this.vocabOnly,
    required this.useMmap,
    required this.useMlock,
    required this.embeddingOnly,
    required this.numThread,
    required this.numKeep,
    required this.seed,
    required this.numPredict,
    required this.topK,
    required this.topP,
    required this.tfsZ,
    required this.typicalP,
    required this.repeatLastN,
    required this.temperature,
    required this.repeatPenalty,
    required this.presencePenalty,
    required this.frequencyPenalty,
    required this.mirostat,
    required this.mirostatTau,
    required this.mirostatEta,
    required this.penalizeNewline,
    required this.stop,
  });

  factory Options.fromJson(Map<String, dynamic> json) => Options(
        numa: json['numa'],
        numCtx: json['num_ctx'],
        numBatch: json['num_batch'],
        numGpu: json['num_gpu'],
        mainGpu: json['main_gpu'],
        lowVram: json['low_vram'],
        f16Kv: json['f16_kv'],
        logitsAll: json['logits_all'],
        vocabOnly: json['vocab_only'],
        useMmap: json['use_mmap'],
        useMlock: json['use_mlock'],
        embeddingOnly: json['embedding_only'],
        numThread: json['num_thread'],
        numKeep: json['num_keep'],
        seed: json['seed'],
        numPredict: json['num_predict'],
        topK: json['top_k'],
        topP: json['top_p'],
        tfsZ: json['tfs_z'],
        typicalP: json['typical_p'],
        repeatLastN: json['repeat_last_n'],
        temperature: json['temperature'],
        repeatPenalty: json['repeat_penalty'],
        presencePenalty: json['presence_penalty'],
        frequencyPenalty: json['frequency_penalty'],
        mirostat: json['mirostat'],
        mirostatTau: json['mirostat_tau'],
        mirostatEta: json['mirostat_eta'],
        penalizeNewline: json['penalize_newline'],
        stop: List<String>.from(json['stop']),
      );

  Map<String, dynamic> toJson() => {
        'numa': numa,
        'num_ctx': numCtx,
        'num_batch': numBatch,
        'num_gpu': numGpu,
        'main_gpu': mainGpu,
        'low_vram': lowVram,
        'f16_kv': f16Kv,
        'logits_all': logitsAll,
        'vocab_only': vocabOnly,
        'use_mmap': useMmap,
        'use_mlock': useMlock,
        'embedding_only': embeddingOnly,
        'num_thread': numThread,
        'num_keep': numKeep,
        'seed': seed,
        'num_predict': numPredict,
        'top_k': topK,
        'top_p': topP,
        'tfs_z': tfsZ,
        'typical_p': typicalP,
        'repeat_last_n': repeatLastN,
        'temperature': temperature,
        'repeat_penalty': repeatPenalty,
        'presence_penalty': presencePenalty,
        'frequency_penalty': frequencyPenalty,
        'mirostat': mirostat,
        'mirostat_tau': mirostatTau,
        'mirostat_eta': mirostatEta,
        'penalize_newline': penalizeNewline,
        'stop': stop,
      };
}

class GenerateRequest {
  final String model;
  final String prompt;
  final String? suffix;
  final String? system;
  final String? template;
  final List<int>? context;
  final bool? stream;
  final bool? raw;
  final dynamic format;
  final List<dynamic>? images;
  final dynamic keepAlive;
  final Options? options;

  GenerateRequest({
    required this.model,
    required this.prompt,
    this.suffix,
    this.system,
    this.template,
    this.context,
    this.stream,
    this.raw,
    this.format,
    this.images,
    this.keepAlive,
    this.options,
  });

  factory GenerateRequest.fromJson(Map<String, dynamic> json) =>
      GenerateRequest(
        model: json['model'],
        prompt: json['prompt'],
        suffix: json['suffix'],
        system: json['system'],
        template: json['template'],
        context: List<int>.from(json['context'] ?? []),
        stream: json['stream'],
        raw: json['raw'],
        format: json['format'],
        images: json['images'],
        keepAlive: json['keep_alive'],
        options:
            json['options'] != null ? Options.fromJson(json['options']) : null,
      );

  Map<String, dynamic> toJson() => {
        'model': model,
        'prompt': prompt,
        'suffix': suffix,
        'system': system,
        'template': template,
        'context': context,
        'stream': stream,
        'raw': raw,
        'format': format,
        'images': images,
        'keep_alive': keepAlive,
        'options': options?.toJson(),
      };
}

class Message {
  final String role;
  final String content;
  final List<dynamic>? images;
  final List<ToolCall>? toolCalls;

  Message({
    required this.role,
    required this.content,
    this.images,
    this.toolCalls,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        role: json['role'],
        content: json['content'],
        images:
            json['images'] != null ? List<dynamic>.from(json['images']) : null,
        toolCalls: json['tool_calls'] != null
            ? (json['tool_calls'] as List)
                .map((item) => ToolCall.fromJson(item))
                .toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'images': images,
        'tool_calls': toolCalls?.map((e) => e.toJson()).toList(),
      };
}

class ToolCall {
  final ToolFunction function;

  ToolCall({
    required this.function,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        function: ToolFunction.fromJson(json['function']),
      );

  Map<String, dynamic> toJson() => {
        'function': function.toJson(),
      };
}

class ToolFunction {
  final String name;
  final Map<String, dynamic> arguments;

  ToolFunction({
    required this.name,
    required this.arguments,
  });

  factory ToolFunction.fromJson(Map<String, dynamic> json) => ToolFunction(
        name: json['name'],
        arguments: Map<String, dynamic>.from(json['arguments']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'arguments': arguments,
      };
}

class Tool {
  final String type;
  final ToolFunctionDetails function;

  Tool({
    required this.type,
    required this.function,
  });

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
        type: json['type'],
        function: ToolFunctionDetails.fromJson(json['function']),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'function': function.toJson(),
      };
}

class ToolFunctionDetails {
  final String name;
  final String description;
  final ToolFunctionParameters parameters;

  ToolFunctionDetails({
    required this.name,
    required this.description,
    required this.parameters,
  });

  factory ToolFunctionDetails.fromJson(Map<String, dynamic> json) =>
      ToolFunctionDetails(
        name: json['name'],
        description: json['description'],
        parameters: ToolFunctionParameters.fromJson(json['parameters']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters.toJson(),
      };
}

class ToolFunctionParameters {
  final String type;
  final List<String> required;
  final Map<String, ToolFunctionProperty> properties;

  ToolFunctionParameters({
    required this.type,
    required this.required,
    required this.properties,
  });

  factory ToolFunctionParameters.fromJson(Map<String, dynamic> json) =>
      ToolFunctionParameters(
        type: json['type'],
        required: List<String>.from(json['required']),
        properties: (json['properties'] as Map<String, dynamic>).map(
            (key, value) =>
                MapEntry(key, ToolFunctionProperty.fromJson(value))),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'required': required,
        'properties':
            properties.map((key, value) => MapEntry(key, value.toJson())),
      };
}

class ToolFunctionProperty {
  final String type;
  final String description;
  final List<String>? enums;

  ToolFunctionProperty({
    required this.type,
    required this.description,
    this.enums,
  });

  factory ToolFunctionProperty.fromJson(Map<String, dynamic> json) =>
      ToolFunctionProperty(
        type: json['type'],
        description: json['description'],
        enums: json['enum'] != null ? List<String>.from(json['enum']) : null,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'enum': enums,
      };
}
