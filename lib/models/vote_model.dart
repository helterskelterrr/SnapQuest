import 'package:cloud_firestore/cloud_firestore.dart';

class VoteModel {
  final String voteId; // format: voterId_submissionId
  final String voterId;
  final String submissionId;
  final String challengeId;
  final Timestamp votedAt;

  const VoteModel({
    required this.voteId,
    required this.voterId,
    required this.submissionId,
    required this.challengeId,
    required this.votedAt,
  });

  factory VoteModel.fromMap(Map<String, dynamic> map, String id) {
    return VoteModel(
      voteId: id,
      voterId: map['voter_id'] as String? ?? '',
      submissionId: map['submission_id'] as String? ?? '',
      challengeId: map['challenge_id'] as String? ?? '',
      votedAt: map['voted_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vote_id': voteId,
      'voter_id': voterId,
      'submission_id': submissionId,
      'challenge_id': challengeId,
      'voted_at': votedAt,
    };
  }
}
