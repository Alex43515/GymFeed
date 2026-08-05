import 'dart:convert';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// Start OpenAI API Assistant Group Code

class OpenAIAPIAssistantGroup {
  static String getBaseUrl({
    String? token = '',
  }) =>
      'https://api.openai.com/v1';
  static Map<String, String> headers = {
    'Authorization': 'Bearer [token]',
    'OpenAI-Beta': 'assistants=v2',
  };
  static ThreadsCall threadsCall = ThreadsCall();
  static MessageCall messageCall = MessageCall();
  static RunCall runCall = RunCall();
  static RetrieverunCall retrieverunCall = RetrieverunCall();
  static MessagesCall messagesCall = MessagesCall();
}

class ThreadsCall {
  Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    final baseUrl = OpenAIAPIAssistantGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'threads',
      apiUrl: '${baseUrl}/threads',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
        'OpenAI-Beta': 'assistants=v2',
      },
      params: {},
      bodyType: BodyType.NONE,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? threadId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.id''',
      ));
}

class MessageCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? content = '',
    String? context = '',
    String? token = '',
  }) async {
    final baseUrl = OpenAIAPIAssistantGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "role": "user",
  "content": "${content}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'message',
      apiUrl: '${baseUrl}/threads/${threadId}/messages',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
        'OpenAI-Beta': 'assistants=v2',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: true,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RunCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? assistantId = '',
    String? instructions = '',
    String? token = '',
  }) async {
    final baseUrl = OpenAIAPIAssistantGroup.getBaseUrl(
      token: token,
    );

    final ffApiRequestBody = '''
{
  "assistant_id": "${assistantId}",
  "instructions": "${instructions}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'run',
      apiUrl: '${baseUrl}/threads/${threadId}/runs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
        'OpenAI-Beta': 'assistants=v2',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: true,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? runId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.id''',
      ));
}

class RetrieverunCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? token = '',
  }) async {
    final baseUrl = OpenAIAPIAssistantGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieverun',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${token}',
        'OpenAI-Beta': 'assistants=v2',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic status(dynamic response) => getJsonField(
        response,
        r'''$.status''',
      );
}

class MessagesCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? token = '',
  }) async {
    final baseUrl = OpenAIAPIAssistantGroup.getBaseUrl(
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'messages',
      apiUrl: '${baseUrl}/threads/${threadId}/messages',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${token}',
        'OpenAI-Beta': 'assistants=v2',
      },
      params: {
        'limit': 1,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic data(dynamic response) => getJsonField(
        response,
        r'''$.data[0].content[0]''',
      );
}

/// End OpenAI API Assistant Group Code

/// Start OpenAI API Group Code

class OpenAIAPIGroup {
  static String getBaseUrl({
    String? apiKey =
        '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',
  }) =>
      'https://api.openai.com/v1';
  static Map<String, String> headers = {};
  static CreateChatCompletionCall createChatCompletionCall =
      CreateChatCompletionCall();
  static CreateCompletionCall createCompletionCall = CreateCompletionCall();
  static CreateImageCall createImageCall = CreateImageCall();
  static CreateImageEditCall createImageEditCall = CreateImageEditCall();
  static CreateImageVariationCall createImageVariationCall =
      CreateImageVariationCall();
  static CreateEmbeddingCall createEmbeddingCall = CreateEmbeddingCall();
  static CreateSpeechCall createSpeechCall = CreateSpeechCall();
  static CreateTranscriptionCall createTranscriptionCall =
      CreateTranscriptionCall();
  static CreateTranslationCall createTranslationCall = CreateTranslationCall();
  static ListFilesCall listFilesCall = ListFilesCall();
  static CreateFileCall createFileCall = CreateFileCall();
  static DeleteFileCall deleteFileCall = DeleteFileCall();
  static RetrieveFileCall retrieveFileCall = RetrieveFileCall();
  static DownloadFileCall downloadFileCall = DownloadFileCall();
  static CreateUploadCall createUploadCall = CreateUploadCall();
  static AddUploadPartCall addUploadPartCall = AddUploadPartCall();
  static CompleteUploadCall completeUploadCall = CompleteUploadCall();
  static CancelUploadCall cancelUploadCall = CancelUploadCall();
  static CreateFineTuningJobCall createFineTuningJobCall =
      CreateFineTuningJobCall();
  static ListPaginatedFineTuningJobsCall listPaginatedFineTuningJobsCall =
      ListPaginatedFineTuningJobsCall();
  static RetrieveFineTuningJobCall retrieveFineTuningJobCall =
      RetrieveFineTuningJobCall();
  static ListFineTuningEventsCall listFineTuningEventsCall =
      ListFineTuningEventsCall();
  static CancelFineTuningJobCall cancelFineTuningJobCall =
      CancelFineTuningJobCall();
  static ListFineTuningJobCheckpointsCall listFineTuningJobCheckpointsCall =
      ListFineTuningJobCheckpointsCall();
  static ListModelsCall listModelsCall = ListModelsCall();
  static RetrieveModelCall retrieveModelCall = RetrieveModelCall();
  static DeleteModelCall deleteModelCall = DeleteModelCall();
  static CreateModerationCall createModerationCall = CreateModerationCall();
  static ListAssistantsCall listAssistantsCall = ListAssistantsCall();
  static CreateAssistantCall createAssistantCall = CreateAssistantCall();
  static GetAssistantCall getAssistantCall = GetAssistantCall();
  static ModifyAssistantCall modifyAssistantCall = ModifyAssistantCall();
  static DeleteAssistantCall deleteAssistantCall = DeleteAssistantCall();
  static CreateThreadCall createThreadCall = CreateThreadCall();
  static GetThreadCall getThreadCall = GetThreadCall();
  static ModifyThreadCall modifyThreadCall = ModifyThreadCall();
  static DeleteThreadCall deleteThreadCall = DeleteThreadCall();
  static ListMessagesCall listMessagesCall = ListMessagesCall();
  static CreateMessageCall createMessageCall = CreateMessageCall();
  static GetMessageCall getMessageCall = GetMessageCall();
  static ModifyMessageCall modifyMessageCall = ModifyMessageCall();
  static DeleteMessageCall deleteMessageCall = DeleteMessageCall();
  static CreateThreadAndRunCall createThreadAndRunCall =
      CreateThreadAndRunCall();
  static ListRunsCall listRunsCall = ListRunsCall();
  static CreateRunCall createRunCall = CreateRunCall();
  static GetRunCall getRunCall = GetRunCall();
  static ModifyRunCall modifyRunCall = ModifyRunCall();
  static SubmitToolOuputsToRunCall submitToolOuputsToRunCall =
      SubmitToolOuputsToRunCall();
  static CancelRunCall cancelRunCall = CancelRunCall();
  static ListRunStepsCall listRunStepsCall = ListRunStepsCall();
  static GetRunStepCall getRunStepCall = GetRunStepCall();
  static ListVectorStoresCall listVectorStoresCall = ListVectorStoresCall();
  static CreateVectorStoreCall createVectorStoreCall = CreateVectorStoreCall();
  static GetVectorStoreCall getVectorStoreCall = GetVectorStoreCall();
  static ModifyVectorStoreCall modifyVectorStoreCall = ModifyVectorStoreCall();
  static DeleteVectorStoreCall deleteVectorStoreCall = DeleteVectorStoreCall();
  static ListVectorStoreFilesCall listVectorStoreFilesCall =
      ListVectorStoreFilesCall();
  static CreateVectorStoreFileCall createVectorStoreFileCall =
      CreateVectorStoreFileCall();
  static GetVectorStoreFileCall getVectorStoreFileCall =
      GetVectorStoreFileCall();
  static DeleteVectorStoreFileCall deleteVectorStoreFileCall =
      DeleteVectorStoreFileCall();
  static CreateVectorStoreFileBatchCall createVectorStoreFileBatchCall =
      CreateVectorStoreFileBatchCall();
  static GetVectorStoreFileBatchCall getVectorStoreFileBatchCall =
      GetVectorStoreFileBatchCall();
  static CancelVectorStoreFileBatchCall cancelVectorStoreFileBatchCall =
      CancelVectorStoreFileBatchCall();
  static ListFilesInVectorStoreBatchCall listFilesInVectorStoreBatchCall =
      ListFilesInVectorStoreBatchCall();
  static CreateBatchCall createBatchCall = CreateBatchCall();
  static ListBatchesCall listBatchesCall = ListBatchesCall();
  static RetrieveBatchCall retrieveBatchCall = RetrieveBatchCall();
  static CancelBatchCall cancelBatchCall = CancelBatchCall();
}

class CreateChatCompletionCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? query = '',
    String? imagePath = '',
    String? assistantId = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "${query}"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "${imagePath}"
          }
        }
      ]
    }
  ],
  "max_tokens": 2000
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createChatCompletion',
      apiUrl: '${baseUrl}/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Bearer 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',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: true,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? resText(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.content''',
      ));
}

class CreateCompletionCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "",
  "prompt": "",
  "best_of": 0,
  "echo": false,
  "frequency_penalty": 0,
  "logit_bias": {},
  "logprobs": 0,
  "max_tokens": 16,
  "n": 1,
  "presence_penalty": 0,
  "seed": 0,
  "stop": "",
  "stream": false,
  "stream_options": {
    "include_usage": false
  },
  "suffix": "test.",
  "temperature": 1,
  "top_p": 1,
  "user": "user-1234"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createCompletion',
      apiUrl: '${baseUrl}/completions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateImageCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "prompt": "A cute baby sea otter",
  "model": "dall-e-3",
  "n": 1,
  "quality": "standard",
  "response_format": "url",
  "size": "1024x1024",
  "style": "vivid",
  "user": "user-1234"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createImage',
      apiUrl: '${baseUrl}/images/generations',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateImageEditCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createImageEdit',
      apiUrl: '${baseUrl}/images/edits',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateImageVariationCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createImageVariation',
      apiUrl: '${baseUrl}/images/variations',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateEmbeddingCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "input": "The quick brown fox jumped over the lazy dog",
  "model": "text-embedding-3-small",
  "encoding_format": "float",
  "dimensions": 0,
  "user": "user-1234"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createEmbedding',
      apiUrl: '${baseUrl}/embeddings',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateSpeechCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "",
  "input": "",
  "voice": "alloy",
  "response_format": "mp3",
  "speed": 0
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createSpeech',
      apiUrl: '${baseUrl}/audio/speech',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateTranscriptionCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createTranscription',
      apiUrl: '${baseUrl}/audio/transcriptions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateTranslationCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createTranslation',
      apiUrl: '${baseUrl}/audio/translations',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListFilesCall {
  Future<ApiCallResponse> call({
    String? purpose = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listFiles',
      apiUrl: '${baseUrl}/files',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'purpose': purpose,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateFileCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createFile',
      apiUrl: '${baseUrl}/files',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteFileCall {
  Future<ApiCallResponse> call({
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteFile',
      apiUrl: '${baseUrl}/files/${fileId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RetrieveFileCall {
  Future<ApiCallResponse> call({
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieveFile',
      apiUrl: '${baseUrl}/files/${fileId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DownloadFileCall {
  Future<ApiCallResponse> call({
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'downloadFile',
      apiUrl: '${baseUrl}/files/${fileId}/content',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateUploadCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "filename": "",
  "purpose": "assistants",
  "bytes": 0,
  "mime_type": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createUpload',
      apiUrl: '${baseUrl}/uploads',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddUploadPartCall {
  Future<ApiCallResponse> call({
    String? uploadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'addUploadPart',
      apiUrl: '${baseUrl}/uploads/${uploadId}/parts',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CompleteUploadCall {
  Future<ApiCallResponse> call({
    String? uploadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "part_ids": [
    ""
  ],
  "md5": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'completeUpload',
      apiUrl: '${baseUrl}/uploads/${uploadId}/complete',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelUploadCall {
  Future<ApiCallResponse> call({
    String? uploadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelUpload',
      apiUrl: '${baseUrl}/uploads/${uploadId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateFineTuningJobCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "gpt-3.5-turbo",
  "training_file": "file-abc123",
  "hyperparameters": {
    "batch_size": "",
    "learning_rate_multiplier": "",
    "n_epochs": ""
  },
  "suffix": "",
  "validation_file": "file-abc123",
  "integrations": [
    {
      "type": "",
      "wandb": {
        "project": "my-wandb-project",
        "name": "",
        "entity": "",
        "tags": [
          "custom-tag"
        ]
      }
    }
  ],
  "seed": 42
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createFineTuningJob',
      apiUrl: '${baseUrl}/fine_tuning/jobs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListPaginatedFineTuningJobsCall {
  Future<ApiCallResponse> call({
    String? after = '',
    int? limit,
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listPaginatedFineTuningJobs',
      apiUrl: '${baseUrl}/fine_tuning/jobs',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'after': after,
        'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RetrieveFineTuningJobCall {
  Future<ApiCallResponse> call({
    String? fineTuningJobId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieveFineTuningJob',
      apiUrl: '${baseUrl}/fine_tuning/jobs/${fineTuningJobId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListFineTuningEventsCall {
  Future<ApiCallResponse> call({
    String? fineTuningJobId = '',
    String? after = '',
    int? limit,
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listFineTuningEvents',
      apiUrl: '${baseUrl}/fine_tuning/jobs/${fineTuningJobId}/events',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'after': after,
        'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelFineTuningJobCall {
  Future<ApiCallResponse> call({
    String? fineTuningJobId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelFineTuningJob',
      apiUrl: '${baseUrl}/fine_tuning/jobs/${fineTuningJobId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListFineTuningJobCheckpointsCall {
  Future<ApiCallResponse> call({
    String? fineTuningJobId = '',
    String? after = '',
    int? limit,
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listFineTuningJobCheckpoints',
      apiUrl: '${baseUrl}/fine_tuning/jobs/${fineTuningJobId}/checkpoints',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'after': after,
        'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListModelsCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listModels',
      apiUrl: '${baseUrl}/models',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RetrieveModelCall {
  Future<ApiCallResponse> call({
    String? model = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieveModel',
      apiUrl: '${baseUrl}/models/${model}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteModelCall {
  Future<ApiCallResponse> call({
    String? model = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteModel',
      apiUrl: '${baseUrl}/models/${model}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateModerationCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "input": "",
  "model": "text-moderation-stable"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createModeration',
      apiUrl: '${baseUrl}/moderations',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListAssistantsCall {
  Future<ApiCallResponse> call({
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listAssistants',
      apiUrl: '${baseUrl}/assistants',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateAssistantCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "gpt-4-turbo",
  "name": "",
  "description": "",
  "instructions": "",
  "tools": [
    ""
  ],
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ],
      "vector_stores": [
        {
          "file_ids": [
            ""
          ],
          "chunking_strategy": {},
          "metadata": {}
        }
      ]
    }
  },
  "metadata": {},
  "temperature": 1,
  "top_p": 1,
  "response_format": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createAssistant',
      apiUrl: '${baseUrl}/assistants',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetAssistantCall {
  Future<ApiCallResponse> call({
    String? assistantId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getAssistant',
      apiUrl: '${baseUrl}/assistants/${assistantId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyAssistantCall {
  Future<ApiCallResponse> call({
    String? assistantId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "",
  "name": "",
  "description": "",
  "instructions": "",
  "tools": [
    ""
  ],
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ]
    }
  },
  "metadata": {},
  "temperature": 1,
  "top_p": 1,
  "response_format": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyAssistant',
      apiUrl: '${baseUrl}/assistants/${assistantId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteAssistantCall {
  Future<ApiCallResponse> call({
    String? assistantId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteAssistant',
      apiUrl: '${baseUrl}/assistants/${assistantId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateThreadCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "messages": [
    {
      "role": "user",
      "content": "",
      "attachments": [
        {
          "file_id": "",
          "tools": [
            ""
          ]
        }
      ],
      "metadata": {}
    }
  ],
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ],
      "vector_stores": [
        {
          "file_ids": [
            ""
          ],
          "chunking_strategy": {},
          "metadata": {}
        }
      ]
    }
  },
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createThread',
      apiUrl: '${baseUrl}/threads',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetThreadCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getThread',
      apiUrl: '${baseUrl}/threads/${threadId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyThreadCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ]
    }
  },
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyThread',
      apiUrl: '${baseUrl}/threads/${threadId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteThreadCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteThread',
      apiUrl: '${baseUrl}/threads/${threadId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListMessagesCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listMessages',
      apiUrl: '${baseUrl}/threads/${threadId}/messages',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
        'run_id': runId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateMessageCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "role": "user",
  "content": "",
  "attachments": [
    {
      "file_id": "",
      "tools": [
        ""
      ]
    }
  ],
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createMessage',
      apiUrl: '${baseUrl}/threads/${threadId}/messages',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetMessageCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? messageId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getMessage',
      apiUrl: '${baseUrl}/threads/${threadId}/messages/${messageId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyMessageCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? messageId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyMessage',
      apiUrl: '${baseUrl}/threads/${threadId}/messages/${messageId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteMessageCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? messageId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteMessage',
      apiUrl: '${baseUrl}/threads/${threadId}/messages/${messageId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateThreadAndRunCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "assistant_id": "",
  "thread": {
    "messages": [
      {
        "role": "user",
        "content": "",
        "attachments": [
          {
            "file_id": "",
            "tools": [
              ""
            ]
          }
        ],
        "metadata": {}
      }
    ],
    "tool_resources": {
      "code_interpreter": {
        "file_ids": [
          ""
        ]
      },
      "file_search": {
        "vector_store_ids": [
          ""
        ],
        "vector_stores": [
          {
            "file_ids": [
              ""
            ],
            "chunking_strategy": {},
            "metadata": {}
          }
        ]
      }
    },
    "metadata": {}
  },
  "model": "gpt-4-turbo",
  "instructions": "",
  "tools": [
    ""
  ],
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ]
    }
  },
  "metadata": {},
  "temperature": 1,
  "top_p": 1,
  "stream": false,
  "max_prompt_tokens": 0,
  "max_completion_tokens": 0,
  "truncation_strategy": {
    "type": "auto",
    "last_messages": 0
  },
  "tool_choice": "",
  "parallel_tool_calls": false,
  "response_format": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createThreadAndRun',
      apiUrl: '${baseUrl}/threads/runs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListRunsCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listRuns',
      apiUrl: '${baseUrl}/threads/${threadId}/runs',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateRunCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "assistant_id": "",
  "model": "gpt-4-turbo",
  "instructions": "",
  "additional_instructions": "",
  "additional_messages": [
    {
      "role": "user",
      "content": "",
      "attachments": [
        {
          "file_id": "",
          "tools": [
            ""
          ]
        }
      ],
      "metadata": {}
    }
  ],
  "tools": [
    ""
  ],
  "metadata": {},
  "temperature": 1,
  "top_p": 1,
  "stream": false,
  "max_prompt_tokens": 0,
  "max_completion_tokens": 0,
  "truncation_strategy": {
    "type": "auto",
    "last_messages": 0
  },
  "tool_choice": "",
  "parallel_tool_calls": false,
  "response_format": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createRun',
      apiUrl: '${baseUrl}/threads/${threadId}/runs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetRunCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getRun',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyRunCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyRun',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class SubmitToolOuputsToRunCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "tool_outputs": [
    {
      "tool_call_id": "",
      "output": ""
    }
  ],
  "stream": false
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'submitToolOuputsToRun',
      apiUrl:
          '${baseUrl}/threads/${threadId}/runs/${runId}/submit_tool_outputs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelRunCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelRun',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListRunStepsCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listRunSteps',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}/steps',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetRunStepCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? stepId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getRunStep',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}/steps/${stepId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListVectorStoresCall {
  Future<ApiCallResponse> call({
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listVectorStores',
      apiUrl: '${baseUrl}/vector_stores',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateVectorStoreCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "file_ids": [
    ""
  ],
  "name": "",
  "expires_after": {
    "anchor": "last_active_at",
    "days": 0
  },
  "chunking_strategy": {},
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createVectorStore',
      apiUrl: '${baseUrl}/vector_stores',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetVectorStoreCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getVectorStore',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyVectorStoreCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "name": "",
  "expires_after": {
    "anchor": "last_active_at",
    "days": 0
  },
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyVectorStore',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteVectorStoreCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteVectorStore',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListVectorStoreFilesCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? filter = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listVectorStoreFiles',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/files',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
        'filter': filter,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateVectorStoreFileCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "file_id": "",
  "chunking_strategy": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createVectorStoreFile',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/files',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetVectorStoreFileCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getVectorStoreFile',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/files/${fileId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteVectorStoreFileCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteVectorStoreFile',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/files/${fileId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateVectorStoreFileBatchCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "file_ids": [
    ""
  ],
  "chunking_strategy": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createVectorStoreFileBatch',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/file_batches',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetVectorStoreFileBatchCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? batchId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getVectorStoreFileBatch',
      apiUrl:
          '${baseUrl}/vector_stores/${vectorStoreId}/file_batches/${batchId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelVectorStoreFileBatchCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? batchId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelVectorStoreFileBatch',
      apiUrl:
          '${baseUrl}/vector_stores/${vectorStoreId}/file_batches/${batchId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListFilesInVectorStoreBatchCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? batchId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? filter = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listFilesInVectorStoreBatch',
      apiUrl:
          '${baseUrl}/vector_stores/${vectorStoreId}/file_batches/${batchId}/files',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
        'filter': filter,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateBatchCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "input_file_id": "",
  "endpoint": "/v1/chat/completions",
  "completion_window": "24h",
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createBatch',
      apiUrl: '${baseUrl}/batches',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListBatchesCall {
  Future<ApiCallResponse> call({
    String? after = '',
    int? limit,
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listBatches',
      apiUrl: '${baseUrl}/batches',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'after': after,
        'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RetrieveBatchCall {
  Future<ApiCallResponse> call({
    String? batchId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieveBatch',
      apiUrl: '${baseUrl}/batches/${batchId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelBatchCall {
  Future<ApiCallResponse> call({
    String? batchId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelBatch',
      apiUrl: '${baseUrl}/batches/${batchId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

/// End OpenAI API Group Code

/// Start OpenAI API GPTResponse Group Code

class OpenAIAPIGPTResponseGroup {
  static String getBaseUrl({
    String? apiKey =
        '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',
  }) =>
      'https://api.openai.com/v1';
  static Map<String, String> headers = {};
  static CreateChatCompletionCopyCall createChatCompletionCopyCall =
      CreateChatCompletionCopyCall();
  static CreateCompletionCopyCall createCompletionCopyCall =
      CreateCompletionCopyCall();
  static CreateImageCopyCall createImageCopyCall = CreateImageCopyCall();
  static CreateImageEditCopyCall createImageEditCopyCall =
      CreateImageEditCopyCall();
  static CreateImageVariationCopyCall createImageVariationCopyCall =
      CreateImageVariationCopyCall();
  static CreateEmbeddingCopyCall createEmbeddingCopyCall =
      CreateEmbeddingCopyCall();
  static CreateSpeechCopyCall createSpeechCopyCall = CreateSpeechCopyCall();
  static CreateTranscriptionCopyCall createTranscriptionCopyCall =
      CreateTranscriptionCopyCall();
  static CreateTranslationCopyCall createTranslationCopyCall =
      CreateTranslationCopyCall();
  static ListFilesCopyCall listFilesCopyCall = ListFilesCopyCall();
  static CreateFileCopyCall createFileCopyCall = CreateFileCopyCall();
  static DeleteFileCopyCall deleteFileCopyCall = DeleteFileCopyCall();
  static RetrieveFileCopyCall retrieveFileCopyCall = RetrieveFileCopyCall();
  static DownloadFileCopyCall downloadFileCopyCall = DownloadFileCopyCall();
  static CreateUploadCopyCall createUploadCopyCall = CreateUploadCopyCall();
  static AddUploadPartCopyCall addUploadPartCopyCall = AddUploadPartCopyCall();
  static CompleteUploadCopyCall completeUploadCopyCall =
      CompleteUploadCopyCall();
  static CancelUploadCopyCall cancelUploadCopyCall = CancelUploadCopyCall();
  static CreateFineTuningJobCopyCall createFineTuningJobCopyCall =
      CreateFineTuningJobCopyCall();
  static ListPaginatedFineTuningJobsCopyCall
      listPaginatedFineTuningJobsCopyCall =
      ListPaginatedFineTuningJobsCopyCall();
  static RetrieveFineTuningJobCopyCall retrieveFineTuningJobCopyCall =
      RetrieveFineTuningJobCopyCall();
  static ListFineTuningEventsCopyCall listFineTuningEventsCopyCall =
      ListFineTuningEventsCopyCall();
  static CancelFineTuningJobCopyCall cancelFineTuningJobCopyCall =
      CancelFineTuningJobCopyCall();
  static ListFineTuningJobCheckpointsCopyCall
      listFineTuningJobCheckpointsCopyCall =
      ListFineTuningJobCheckpointsCopyCall();
  static ListModelsCopyCall listModelsCopyCall = ListModelsCopyCall();
  static RetrieveModelCopyCall retrieveModelCopyCall = RetrieveModelCopyCall();
  static DeleteModelCopyCall deleteModelCopyCall = DeleteModelCopyCall();
  static CreateModerationCopyCall createModerationCopyCall =
      CreateModerationCopyCall();
  static ListAssistantsCopyCall listAssistantsCopyCall =
      ListAssistantsCopyCall();
  static CreateAssistantCopyCall createAssistantCopyCall =
      CreateAssistantCopyCall();
  static GetAssistantCopyCall getAssistantCopyCall = GetAssistantCopyCall();
  static ModifyAssistantCopyCall modifyAssistantCopyCall =
      ModifyAssistantCopyCall();
  static DeleteAssistantCopyCall deleteAssistantCopyCall =
      DeleteAssistantCopyCall();
  static CreateThreadCopyCall createThreadCopyCall = CreateThreadCopyCall();
  static GetThreadCopyCall getThreadCopyCall = GetThreadCopyCall();
  static ModifyThreadCopyCall modifyThreadCopyCall = ModifyThreadCopyCall();
  static DeleteThreadCopyCall deleteThreadCopyCall = DeleteThreadCopyCall();
  static ListMessagesCopyCall listMessagesCopyCall = ListMessagesCopyCall();
  static CreateMessageCopyCall createMessageCopyCall = CreateMessageCopyCall();
  static GetMessageCopyCall getMessageCopyCall = GetMessageCopyCall();
  static ModifyMessageCopyCall modifyMessageCopyCall = ModifyMessageCopyCall();
  static DeleteMessageCopyCall deleteMessageCopyCall = DeleteMessageCopyCall();
  static CreateThreadAndRunCopyCall createThreadAndRunCopyCall =
      CreateThreadAndRunCopyCall();
  static ListRunsCopyCall listRunsCopyCall = ListRunsCopyCall();
  static CreateRunCopyCall createRunCopyCall = CreateRunCopyCall();
  static GetRunCopyCall getRunCopyCall = GetRunCopyCall();
  static ModifyRunCopyCall modifyRunCopyCall = ModifyRunCopyCall();
  static SubmitToolOuputsToRunCopyCall submitToolOuputsToRunCopyCall =
      SubmitToolOuputsToRunCopyCall();
  static CancelRunCopyCall cancelRunCopyCall = CancelRunCopyCall();
  static ListRunStepsCopyCall listRunStepsCopyCall = ListRunStepsCopyCall();
  static GetRunStepCopyCall getRunStepCopyCall = GetRunStepCopyCall();
  static ListVectorStoresCopyCall listVectorStoresCopyCall =
      ListVectorStoresCopyCall();
  static CreateVectorStoreCopyCall createVectorStoreCopyCall =
      CreateVectorStoreCopyCall();
  static GetVectorStoreCopyCall getVectorStoreCopyCall =
      GetVectorStoreCopyCall();
  static ModifyVectorStoreCopyCall modifyVectorStoreCopyCall =
      ModifyVectorStoreCopyCall();
  static DeleteVectorStoreCopyCall deleteVectorStoreCopyCall =
      DeleteVectorStoreCopyCall();
  static ListVectorStoreFilesCopyCall listVectorStoreFilesCopyCall =
      ListVectorStoreFilesCopyCall();
  static CreateVectorStoreFileCopyCall createVectorStoreFileCopyCall =
      CreateVectorStoreFileCopyCall();
  static GetVectorStoreFileCopyCall getVectorStoreFileCopyCall =
      GetVectorStoreFileCopyCall();
  static DeleteVectorStoreFileCopyCall deleteVectorStoreFileCopyCall =
      DeleteVectorStoreFileCopyCall();
  static CreateVectorStoreFileBatchCopyCall createVectorStoreFileBatchCopyCall =
      CreateVectorStoreFileBatchCopyCall();
  static GetVectorStoreFileBatchCopyCall getVectorStoreFileBatchCopyCall =
      GetVectorStoreFileBatchCopyCall();
  static CancelVectorStoreFileBatchCopyCall cancelVectorStoreFileBatchCopyCall =
      CancelVectorStoreFileBatchCopyCall();
  static ListFilesInVectorStoreBatchCopyCall
      listFilesInVectorStoreBatchCopyCall =
      ListFilesInVectorStoreBatchCopyCall();
  static CreateBatchCopyCall createBatchCopyCall = CreateBatchCopyCall();
  static ListBatchesCopyCall listBatchesCopyCall = ListBatchesCopyCall();
  static RetrieveBatchCopyCall retrieveBatchCopyCall = RetrieveBatchCopyCall();
  static CancelBatchCopyCall cancelBatchCopyCall = CancelBatchCopyCall();
}

class CreateChatCompletionCopyCall {
  Future<ApiCallResponse> call({
    String? query = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "${query}"
        }
      ]
    }
  ],
"max_tokens": 2000
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createChatCompletion Copy',
      apiUrl: '${baseUrl}/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Bearer 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',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: true,
      decodeUtf8: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? resText(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.content''',
      ));
}

class CreateCompletionCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "",
  "prompt": "",
  "best_of": 0,
  "echo": false,
  "frequency_penalty": 0,
  "logit_bias": {},
  "logprobs": 0,
  "max_tokens": 16,
  "n": 1,
  "presence_penalty": 0,
  "seed": 0,
  "stop": "",
  "stream": false,
  "stream_options": {
    "include_usage": false
  },
  "suffix": "test.",
  "temperature": 1,
  "top_p": 1,
  "user": "user-1234"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createCompletion Copy',
      apiUrl: '${baseUrl}/completions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateImageCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "prompt": "A cute baby sea otter",
  "model": "dall-e-3",
  "n": 1,
  "quality": "standard",
  "response_format": "url",
  "size": "1024x1024",
  "style": "vivid",
  "user": "user-1234"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createImage Copy',
      apiUrl: '${baseUrl}/images/generations',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateImageEditCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createImageEdit Copy',
      apiUrl: '${baseUrl}/images/edits',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateImageVariationCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createImageVariation Copy',
      apiUrl: '${baseUrl}/images/variations',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateEmbeddingCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "input": "The quick brown fox jumped over the lazy dog",
  "model": "text-embedding-3-small",
  "encoding_format": "float",
  "dimensions": 0,
  "user": "user-1234"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createEmbedding Copy',
      apiUrl: '${baseUrl}/embeddings',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateSpeechCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "",
  "input": "",
  "voice": "alloy",
  "response_format": "mp3",
  "speed": 0
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createSpeech Copy',
      apiUrl: '${baseUrl}/audio/speech',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateTranscriptionCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createTranscription Copy',
      apiUrl: '${baseUrl}/audio/transcriptions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateTranslationCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createTranslation Copy',
      apiUrl: '${baseUrl}/audio/translations',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListFilesCopyCall {
  Future<ApiCallResponse> call({
    String? purpose = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listFiles Copy',
      apiUrl: '${baseUrl}/files',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'purpose': purpose,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateFileCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'createFile Copy',
      apiUrl: '${baseUrl}/files',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteFileCopyCall {
  Future<ApiCallResponse> call({
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteFile Copy',
      apiUrl: '${baseUrl}/files/${fileId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RetrieveFileCopyCall {
  Future<ApiCallResponse> call({
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieveFile Copy',
      apiUrl: '${baseUrl}/files/${fileId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DownloadFileCopyCall {
  Future<ApiCallResponse> call({
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'downloadFile Copy',
      apiUrl: '${baseUrl}/files/${fileId}/content',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateUploadCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "filename": "",
  "purpose": "assistants",
  "bytes": 0,
  "mime_type": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createUpload Copy',
      apiUrl: '${baseUrl}/uploads',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddUploadPartCopyCall {
  Future<ApiCallResponse> call({
    String? uploadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'addUploadPart Copy',
      apiUrl: '${baseUrl}/uploads/${uploadId}/parts',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CompleteUploadCopyCall {
  Future<ApiCallResponse> call({
    String? uploadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "part_ids": [
    ""
  ],
  "md5": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'completeUpload Copy',
      apiUrl: '${baseUrl}/uploads/${uploadId}/complete',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelUploadCopyCall {
  Future<ApiCallResponse> call({
    String? uploadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelUpload Copy',
      apiUrl: '${baseUrl}/uploads/${uploadId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateFineTuningJobCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "gpt-3.5-turbo",
  "training_file": "file-abc123",
  "hyperparameters": {
    "batch_size": "",
    "learning_rate_multiplier": "",
    "n_epochs": ""
  },
  "suffix": "",
  "validation_file": "file-abc123",
  "integrations": [
    {
      "type": "",
      "wandb": {
        "project": "my-wandb-project",
        "name": "",
        "entity": "",
        "tags": [
          "custom-tag"
        ]
      }
    }
  ],
  "seed": 42
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createFineTuningJob Copy',
      apiUrl: '${baseUrl}/fine_tuning/jobs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListPaginatedFineTuningJobsCopyCall {
  Future<ApiCallResponse> call({
    String? after = '',
    int? limit,
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listPaginatedFineTuningJobs Copy',
      apiUrl: '${baseUrl}/fine_tuning/jobs',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'after': after,
        'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RetrieveFineTuningJobCopyCall {
  Future<ApiCallResponse> call({
    String? fineTuningJobId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieveFineTuningJob Copy',
      apiUrl: '${baseUrl}/fine_tuning/jobs/${fineTuningJobId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListFineTuningEventsCopyCall {
  Future<ApiCallResponse> call({
    String? fineTuningJobId = '',
    String? after = '',
    int? limit,
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listFineTuningEvents Copy',
      apiUrl: '${baseUrl}/fine_tuning/jobs/${fineTuningJobId}/events',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'after': after,
        'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelFineTuningJobCopyCall {
  Future<ApiCallResponse> call({
    String? fineTuningJobId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelFineTuningJob Copy',
      apiUrl: '${baseUrl}/fine_tuning/jobs/${fineTuningJobId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListFineTuningJobCheckpointsCopyCall {
  Future<ApiCallResponse> call({
    String? fineTuningJobId = '',
    String? after = '',
    int? limit,
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listFineTuningJobCheckpoints Copy',
      apiUrl: '${baseUrl}/fine_tuning/jobs/${fineTuningJobId}/checkpoints',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'after': after,
        'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListModelsCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listModels Copy',
      apiUrl: '${baseUrl}/models',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RetrieveModelCopyCall {
  Future<ApiCallResponse> call({
    String? model = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieveModel Copy',
      apiUrl: '${baseUrl}/models/${model}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteModelCopyCall {
  Future<ApiCallResponse> call({
    String? model = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteModel Copy',
      apiUrl: '${baseUrl}/models/${model}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateModerationCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "input": "",
  "model": "text-moderation-stable"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createModeration Copy',
      apiUrl: '${baseUrl}/moderations',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListAssistantsCopyCall {
  Future<ApiCallResponse> call({
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listAssistants Copy',
      apiUrl: '${baseUrl}/assistants',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateAssistantCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "gpt-4-turbo",
  "name": "",
  "description": "",
  "instructions": "",
  "tools": [
    ""
  ],
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ],
      "vector_stores": [
        {
          "file_ids": [
            ""
          ],
          "chunking_strategy": {},
          "metadata": {}
        }
      ]
    }
  },
  "metadata": {},
  "temperature": 1,
  "top_p": 1,
  "response_format": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createAssistant Copy',
      apiUrl: '${baseUrl}/assistants',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetAssistantCopyCall {
  Future<ApiCallResponse> call({
    String? assistantId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getAssistant Copy',
      apiUrl: '${baseUrl}/assistants/${assistantId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyAssistantCopyCall {
  Future<ApiCallResponse> call({
    String? assistantId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "model": "",
  "name": "",
  "description": "",
  "instructions": "",
  "tools": [
    ""
  ],
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ]
    }
  },
  "metadata": {},
  "temperature": 1,
  "top_p": 1,
  "response_format": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyAssistant Copy',
      apiUrl: '${baseUrl}/assistants/${assistantId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteAssistantCopyCall {
  Future<ApiCallResponse> call({
    String? assistantId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteAssistant Copy',
      apiUrl: '${baseUrl}/assistants/${assistantId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateThreadCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "messages": [
    {
      "role": "user",
      "content": "",
      "attachments": [
        {
          "file_id": "",
          "tools": [
            ""
          ]
        }
      ],
      "metadata": {}
    }
  ],
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ],
      "vector_stores": [
        {
          "file_ids": [
            ""
          ],
          "chunking_strategy": {},
          "metadata": {}
        }
      ]
    }
  },
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createThread Copy',
      apiUrl: '${baseUrl}/threads',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetThreadCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getThread Copy',
      apiUrl: '${baseUrl}/threads/${threadId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyThreadCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ]
    }
  },
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyThread Copy',
      apiUrl: '${baseUrl}/threads/${threadId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteThreadCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteThread Copy',
      apiUrl: '${baseUrl}/threads/${threadId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListMessagesCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listMessages Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/messages',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
        'run_id': runId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateMessageCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "role": "user",
  "content": "",
  "attachments": [
    {
      "file_id": "",
      "tools": [
        ""
      ]
    }
  ],
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createMessage Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/messages',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetMessageCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? messageId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getMessage Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/messages/${messageId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyMessageCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? messageId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyMessage Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/messages/${messageId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteMessageCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? messageId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteMessage Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/messages/${messageId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateThreadAndRunCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "assistant_id": "",
  "thread": {
    "messages": [
      {
        "role": "user",
        "content": "",
        "attachments": [
          {
            "file_id": "",
            "tools": [
              ""
            ]
          }
        ],
        "metadata": {}
      }
    ],
    "tool_resources": {
      "code_interpreter": {
        "file_ids": [
          ""
        ]
      },
      "file_search": {
        "vector_store_ids": [
          ""
        ],
        "vector_stores": [
          {
            "file_ids": [
              ""
            ],
            "chunking_strategy": {},
            "metadata": {}
          }
        ]
      }
    },
    "metadata": {}
  },
  "model": "gpt-4-turbo",
  "instructions": "",
  "tools": [
    ""
  ],
  "tool_resources": {
    "code_interpreter": {
      "file_ids": [
        ""
      ]
    },
    "file_search": {
      "vector_store_ids": [
        ""
      ]
    }
  },
  "metadata": {},
  "temperature": 1,
  "top_p": 1,
  "stream": false,
  "max_prompt_tokens": 0,
  "max_completion_tokens": 0,
  "truncation_strategy": {
    "type": "auto",
    "last_messages": 0
  },
  "tool_choice": "",
  "parallel_tool_calls": false,
  "response_format": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createThreadAndRun Copy',
      apiUrl: '${baseUrl}/threads/runs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListRunsCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listRuns Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/runs',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateRunCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "assistant_id": "",
  "model": "gpt-4-turbo",
  "instructions": "",
  "additional_instructions": "",
  "additional_messages": [
    {
      "role": "user",
      "content": "",
      "attachments": [
        {
          "file_id": "",
          "tools": [
            ""
          ]
        }
      ],
      "metadata": {}
    }
  ],
  "tools": [
    ""
  ],
  "metadata": {},
  "temperature": 1,
  "top_p": 1,
  "stream": false,
  "max_prompt_tokens": 0,
  "max_completion_tokens": 0,
  "truncation_strategy": {
    "type": "auto",
    "last_messages": 0
  },
  "tool_choice": "",
  "parallel_tool_calls": false,
  "response_format": ""
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createRun Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/runs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetRunCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getRun Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyRunCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyRun Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class SubmitToolOuputsToRunCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "tool_outputs": [
    {
      "tool_call_id": "",
      "output": ""
    }
  ],
  "stream": false
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'submitToolOuputsToRun Copy',
      apiUrl:
          '${baseUrl}/threads/${threadId}/runs/${runId}/submit_tool_outputs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelRunCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelRun Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListRunStepsCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listRunSteps Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}/steps',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetRunStepCopyCall {
  Future<ApiCallResponse> call({
    String? threadId = '',
    String? runId = '',
    String? stepId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getRunStep Copy',
      apiUrl: '${baseUrl}/threads/${threadId}/runs/${runId}/steps/${stepId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListVectorStoresCopyCall {
  Future<ApiCallResponse> call({
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listVectorStores Copy',
      apiUrl: '${baseUrl}/vector_stores',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateVectorStoreCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "file_ids": [
    ""
  ],
  "name": "",
  "expires_after": {
    "anchor": "last_active_at",
    "days": 0
  },
  "chunking_strategy": {},
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createVectorStore Copy',
      apiUrl: '${baseUrl}/vector_stores',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetVectorStoreCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getVectorStore Copy',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ModifyVectorStoreCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "name": "",
  "expires_after": {
    "anchor": "last_active_at",
    "days": 0
  },
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'modifyVectorStore Copy',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteVectorStoreCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteVectorStore Copy',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListVectorStoreFilesCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? filter = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listVectorStoreFiles Copy',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/files',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
        'filter': filter,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateVectorStoreFileCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "file_id": "",
  "chunking_strategy": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createVectorStoreFile Copy',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/files',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetVectorStoreFileCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getVectorStoreFile Copy',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/files/${fileId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteVectorStoreFileCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? fileId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'deleteVectorStoreFile Copy',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/files/${fileId}',
      callType: ApiCallType.DELETE,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateVectorStoreFileBatchCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "file_ids": [
    ""
  ],
  "chunking_strategy": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createVectorStoreFileBatch Copy',
      apiUrl: '${baseUrl}/vector_stores/${vectorStoreId}/file_batches',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetVectorStoreFileBatchCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? batchId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'getVectorStoreFileBatch Copy',
      apiUrl:
          '${baseUrl}/vector_stores/${vectorStoreId}/file_batches/${batchId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelVectorStoreFileBatchCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? batchId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelVectorStoreFileBatch Copy',
      apiUrl:
          '${baseUrl}/vector_stores/${vectorStoreId}/file_batches/${batchId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListFilesInVectorStoreBatchCopyCall {
  Future<ApiCallResponse> call({
    String? vectorStoreId = '',
    String? batchId = '',
    int? limit,
    String? order = '',
    String? after = '',
    String? before = '',
    String? filter = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listFilesInVectorStoreBatch Copy',
      apiUrl:
          '${baseUrl}/vector_stores/${vectorStoreId}/file_batches/${batchId}/files',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'limit': limit,
        'order': order,
        'after': after,
        'before': before,
        'filter': filter,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CreateBatchCopyCall {
  Future<ApiCallResponse> call({
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    final ffApiRequestBody = '''
{
  "input_file_id": "",
  "endpoint": "/v1/chat/completions",
  "completion_window": "24h",
  "metadata": {}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'createBatch Copy',
      apiUrl: '${baseUrl}/batches',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ListBatchesCopyCall {
  Future<ApiCallResponse> call({
    String? after = '',
    int? limit,
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'listBatches Copy',
      apiUrl: '${baseUrl}/batches',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {
        'after': after,
        'limit': limit,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RetrieveBatchCopyCall {
  Future<ApiCallResponse> call({
    String? batchId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'retrieveBatch Copy',
      apiUrl: '${baseUrl}/batches/${batchId}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CancelBatchCopyCall {
  Future<ApiCallResponse> call({
    String? batchId = '',
    String? apiKeyAuth = '',
    String? apiKey =
        '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',
  }) async {
    final baseUrl = OpenAIAPIGPTResponseGroup.getBaseUrl(
      apiKey: apiKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'cancelBatch Copy',
      apiUrl: '${baseUrl}/batches/${batchId}/cancel',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${apiKeyAuth}',
      },
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

/// End OpenAI API GPTResponse Group Code

class ImageTestCall {
  static Future<ApiCallResponse> call({
    String? image = '',
    String? video = '',
  }) async {
    final ffApiRequestBody = '''
{
  "inputs": [
    {
      "data": {
        "image": {
          "url": "${image}"
        }
      }
    }
  ]
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'imageTest',
      apiUrl:
          'https://api.clarifai.com/v2/users/pf7zfb6j2nbk/apps/instagram/models/general-image-recognition/versions/aa7f35c01e0642fda5cf400f543e7c40/outputs',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Key API_KEY_HERE',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<String>? labels(dynamic response) => (getJsonField(
        response,
        r'''$.outputs[:].data.concepts[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}
