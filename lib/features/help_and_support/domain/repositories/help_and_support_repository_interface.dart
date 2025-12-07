import 'dart:io';

import 'package:get/get_connect/http/src/response/response.dart';
import 'package:dir_delivery_driver/data/api_client.dart';
import 'package:dir_delivery_driver/Interface/repository_interface.dart';

abstract class HelpAndSupportRepositoryInterface implements RepositoryInterface {
  Future<Response> createChannel();
  Future<Response> getPredefineFaqList();
  Future<Response> sendMessage(
      {String? message, String? channelId, List<MultipartBody>? images, List<MultipartDocument>? documents});
  Future<Response> sendFaqMessage({String? questionId, String? channelId});
  Future<Response> getConversation(String channelId, int offset);
  Future<HttpClientResponse> downloadFile(String url);
}
