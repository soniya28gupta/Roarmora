import 'package:flutter_test/flutter_test.dart';
import 'package:roamora_flutter/core/utils/distance_calculator.dart';
import 'package:roamora_flutter/models/user_model.dart';
import 'package:roamora_flutter/models/match_model.dart';
import 'package:roamora_flutter/models/message_model.dart';
import 'package:roamora_flutter/models/call_session_model.dart';
import 'package:roamora_flutter/models/game_session_model.dart';

void main() {
  group('Feature 16: Distance Calculations & Haversine Accuracy', () {
    test('calculates accurate distance between Delhi coordinates', () {
      // Hauz Khas (28.5535, 77.1942) to Lodhi Gardens (28.5891, 77.2215)
      final distanceKm = DistanceCalculator.calculateDistanceKm(
        lat1: 28.5535,
        lon1: 77.1942,
        lat2: 28.5891,
        lon2: 77.2215,
      );

      expect(distanceKm, greaterThan(4.5));
      expect(distanceKm, lessThan(5.5));
    });

    test('formats distance in meters when under 1 km', () {
      final formatted = DistanceCalculator.formatDistance(
        lat1: 28.5535,
        lon1: 77.1942,
        lat2: 28.5570,
        lon2: 77.1970,
      );

      expect(formatted, contains('m away'));
    });

    test('formats distance in kilometers when 1 km or greater', () {
      final formatted = DistanceCalculator.formatDistance(
        lat1: 28.5535,
        lon1: 77.1942,
        lat2: 28.5891,
        lon2: 77.2215,
      );

      expect(formatted, contains('km away'));
    });
  });

  group('Authentication & Profile Models', () {
    test('parses UserModel with nested Profile and Preferences', () {
      final json = {
        'id': 'user-123',
        'email': 'soniya@example.com',
        'age': 24,
        'profile': {
          'displayName': 'Soniya Gupta',
          'bio': 'Coffee enthusiast and explorer',
          'city': 'New Delhi',
          'interests': ['Cafés', 'Travel'],
          'discoverable': true,
        },
        'preferences': {
          'locationConsent': true,
          'discoveryRadiusMeters': 500,
        },
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.email, 'soniya@example.com');
      expect(user.profile?.displayName, 'Soniya Gupta');
      expect(user.preferences?.locationConsent, true);
      expect(user.preferences?.discoveryRadiusMeters, 500);
    });
  });

  group('Discovery & Matching Models', () {
    test('parses MatchModel with compatibility score and coordinates', () {
      final json = {
        'id': 'match-456',
        'otherUserId': 'nikhil-id',
        'displayName': 'Nikhil Goyal',
        'age': 25,
        'city': 'New Delhi',
        'bio': 'Designer & city walker',
        'interests': ['Outdoors', 'Live music'],
        'latitude': 28.5620,
        'longitude': 77.2010,
        'locationConsent': true,
        'compatibility': {'percentage': 92},
      };

      final match = MatchModel.fromJson(json);
      expect(match.name, 'Nikhil Goyal');
      expect(match.age, 25);
      expect(match.latitude, 28.5620);
      expect(match.longitude, 77.2010);
      expect(match.locationShared, true);
      expect(match.compatibility?['percentage'], 92);
    });
  });

  group('Chat & Messaging Models', () {
    test('parses MessageModel and accurately checks sender', () {
      final json = {
        'id': 'msg-1',
        'senderId': 'user-123',
        'body': 'Hey, want to grab coffee at Hauz Khas?',
        'createdAt': '2026-11-02T10:00:00.000Z',
      };

      final myMsg = MessageModel.fromJson(json, currentUserId: 'user-123');
      expect(myMsg.fromMe, true);
      expect(myMsg.body, 'Hey, want to grab coffee at Hauz Khas?');

      final otherMsg = MessageModel.fromJson(json, currentUserId: 'user-999');
      expect(otherMsg.fromMe, false);
    });
  });

  group('WebRTC Call Session Lifecycle', () {
    test('parses CallSessionModel with SKIPPED status', () {
      final json = {
        'id': 'call-789',
        'callerId': 'soniya-id',
        'calleeId': 'nikhil-id',
        'matchId': 'match-1',
        'callType': 'VIDEO',
        'status': 'SKIPPED',
        'caller': {
          'profile': {'displayName': 'Soniya Gupta'}
        },
      };

      final call = CallSessionModel.fromJson(json);
      expect(call.id, 'call-789');
      expect(call.status, 'SKIPPED');
      expect(call.callerName, 'Soniya Gupta');
    });

    test('parses CallSessionModel with ACCEPTED status and WebRTC SDP offer/answer', () {
      final json = {
        'id': 'call-100',
        'callerId': 'soniya-id',
        'calleeId': 'nikhil-id',
        'matchId': 'match-1',
        'callType': 'VIDEO',
        'status': 'ACCEPTED',
        'offer': {'type': 'offer', 'sdp': 'v=0\r\no=...'},
        'answer': {'type': 'answer', 'sdp': 'v=0\r\no=...'},
      };

      final call = CallSessionModel.fromJson(json);
      expect(call.status, 'ACCEPTED');
      expect(call.offer?['type'], 'offer');
      expect(call.answer?['type'], 'answer');
    });
  });

  group('Multiplayer Game Session Models', () {
    test('parses GameSessionModel with participants, scores and turns', () {
      final json = {
        'id': 'game-001',
        'gameType': 'VIBE_CHECK',
        'hostId': 'soniya-id',
        'status': 'ACTIVE',
        'participants': [
          {
            'id': 'part-1',
            'userId': 'soniya-id',
            'score': 50,
            'completed': false,
            'user': {
              'profile': {'displayName': 'Soniya'}
            }
          },
          {
            'id': 'part-2',
            'userId': 'nikhil-id',
            'score': 25,
            'completed': false,
            'user': {
              'profile': {'displayName': 'Nikhil'}
            }
          }
        ],
      };

      final session = GameSessionModel.fromJson(json);
      expect(session.gameType, 'VIBE_CHECK');
      expect(session.gameLabel, 'Vibe Check Trivia');
      expect(session.participants.length, 2);
      expect(session.participants[0].score, 50);
      expect(session.participants[1].score, 25);
    });
  });
}

