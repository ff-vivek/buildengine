import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:buildengine_server/server.dart';

void main() {
  group('BuildEngine Server Tests', () {
    late BuildEngineServer server;
    late String baseUrl;

    setUpAll(() async {
      server = BuildEngineServer();
      baseUrl = 'http://127.0.0.1:8787';

      // Start server in background
      await server.start();

      // Wait for server to start
      await Future.delayed(Duration(seconds: 1));
    });

    tearDownAll(() async {
      // Server will be stopped by the process signal handler
    });

    test('Health check endpoint', () async {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'application/json');

      final body = jsonDecode(response.body);
      expect(body['status'], 'healthy');
    });

    test('Initialize upload', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/uploads'),
        headers: {'Accept': 'application/json'},
      );

      expect(response.statusCode, 201);
      expect(response.headers['content-type'], 'application/json');

      final body = jsonDecode(response.body);
      expect(body['uploadId'], isA<String>());
      expect(body['uploadId'], startsWith('upl_'));
    });

    test('Create job with upload source', () async {
      // First initialize upload
      final uploadResponse = await http.post(
        Uri.parse('$baseUrl/v1/uploads'),
        headers: {'Accept': 'application/json'},
      );
      final uploadData = jsonDecode(uploadResponse.body);
      final uploadId = uploadData['uploadId'];

      // Create job
      final jobData = {
        'source': {
          'type': 'uploadZip',
          'uploadId': uploadId,
        },
        'config': {
          'flutterVersion': 'default',
          'buildType': 'release',
          'targetFile': 'lib/main.dart',
        }
      };

      final response = await http.post(
        Uri.parse('$baseUrl/v1/jobs'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(jobData),
      );

      expect(response.statusCode, 201);
      expect(response.headers['content-type'], 'application/json');

      final body = jsonDecode(response.body);
      expect(body['id'], isA<String>());
      expect(body['id'], startsWith('job_'));
      expect(body['status'], 'created');
      expect(body['createdAt'], isA<String>());
    });

    test('Get jobs list', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/jobs'),
        headers: {'Accept': 'application/json'},
      );

      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'application/json');

      final body = jsonDecode(response.body);
      expect(body['jobs'], isA<List>());
      expect(body['total'], isA<int>());
      expect(body['page'], 1);
      expect(body['limit'], 20);
      expect(body['hasMore'], isA<bool>());
    });

    test('Invalid job ID returns 404', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/jobs/invalid_job_id'),
        headers: {'Accept': 'application/json'},
      );

      expect(response.statusCode, 404);
      expect(response.headers['content-type'], 'application/json');

      final body = jsonDecode(response.body);
      expect(body['message'], 'Job not found');
    });

    test('Invalid request returns 400', () async {
      final invalidData = {
        'source': {
          'type': 'uploadZip',
          // Missing uploadId
        },
        'config': {
          'flutterVersion': 'default',
          'buildType': 'release',
        }
      };

      final response = await http.post(
        Uri.parse('$baseUrl/v1/jobs'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(invalidData),
      );

      expect(response.statusCode, 400);
      expect(response.headers['content-type'], 'application/json');

      final body = jsonDecode(response.body);
      expect(body['message'], contains('uploadId is required'));
    });
  });
}
