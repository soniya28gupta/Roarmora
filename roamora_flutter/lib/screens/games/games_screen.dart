import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/games_provider.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  int _triviaIndex = 0;
  int? _selectedTriviaOpt;
  bool _triviaFinished = false;

  final TextEditingController _tdController = TextEditingController();
  int _tdPromptIndex = 0;
  bool _isTruth = true;

  final List<Map<String, dynamic>> _triviaQuestions = [
    {
      'q': 'Where was the historic 13th-century water reservoir Hauz Khas originally built?',
      'opts': ['Jaipur', 'New Delhi', 'Lucknow', 'Bhopal'],
      'correct': 1,
      'fact': 'Built by Alauddin Khalji to supply water to Siri Fort.',
    },
    {
      'q': 'When is the photographic "golden hour" best enjoyed?',
      'opts': ['High noon', 'Just after sunrise or before sunset', 'Midnight', '3 PM'],
      'correct': 1,
      'fact': 'The warm low-angle sun produces dreamy, flattering portrait light.',
    },
    {
      'q': 'What does the serene wellness practice of "Shinrin-yoku" mean?',
      'opts': ['Tea ritual', 'Forest bathing & nature immersion', 'Pottery', 'Silent poetry'],
      'correct': 1,
      'fact': 'Immersing your senses in trees lowers cortisol and sparks deep calm.',
    },
    {
      'q': 'In Italian coffee culture, what is an "Affogato"?',
      'opts': ['Espresso over creamy gelato', 'Extra dark roast', 'Cold brew', 'Flat white'],
      'correct': 0,
      'fact': 'Affogato literally means "drowned" in Italian: hot espresso over cold gelato.',
    },
  ];

  final List<String> _truthPrompts = [
    'What’s an unconventional hobby or interest you genuinely love that surprises people?',
    'What’s your favorite memory of a walk where conversation just flowed effortlessly?',
    'If you could teleport us anywhere for dinner tonight, what vibe would you pick?',
    'What is a movie, book, or album that fundamentally shifted how you look at the world?',
  ];

  final List<String> _darePrompts = [
    'Recommend a song that feels like your personal theme song this week.',
    'Share a quick haiku (5-7-5 syllables) describing your ideal weekend escape.',
    'Describe your favorite café in three adjectives without naming it.',
  ];

  @override
  void dispose() {
    _tdController.dispose();
    super.dispose();
  }

  void _handleTriviaAnswer(int optIdx) {
    if (_selectedTriviaOpt != null) return;
    setState(() => _selectedTriviaOpt = optIdx);
    final isCorrect = optIdx == _triviaQuestions[_triviaIndex]['correct'];
    if (isCorrect) {
      ref.read(gamesProvider.notifier).addTriviaScore(25);
    }

    // Sync multiplayer score if in room
    ref.read(gamesProvider.notifier).submitGameAction(
      'answer_$_triviaIndex',
      {'correct': isCorrect, 'score': isCorrect ? 25 : 0},
    );

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_triviaIndex < _triviaQuestions.length - 1) {
        setState(() {
          _triviaIndex++;
          _selectedTriviaOpt = null;
        });
      } else {
        setState(() => _triviaFinished = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gamesState = ref.watch(gamesProvider);
    final gamesNotifier = ref.read(gamesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-Games & Quests'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector: Solo vs Play with Match
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => gamesNotifier.setPlayMode('solo'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: gamesState.playMode == 'solo' ? AppColors.coral : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                color: gamesState.playMode == 'solo' ? Colors.white : AppColors.textMuted,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Solo Play',
                                style: TextStyle(
                                  color: gamesState.playMode == 'solo' ? Colors.white : AppColors.ink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => gamesNotifier.setPlayMode('multiplayer'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: gamesState.playMode == 'multiplayer' ? AppColors.coral : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                color: gamesState.playMode == 'multiplayer' ? Colors.white : AppColors.textMuted,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Play with Match',
                                style: TextStyle(
                                  color: gamesState.playMode == 'multiplayer' ? Colors.white : AppColors.ink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Multiplayer Match Selector & Room Banner
            if (gamesState.playMode == 'multiplayer') ...[
              _buildMultiplayerHeader(gamesState, gamesNotifier),
              const SizedBox(height: 16),
            ],

            // Game Tabs Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip('quiz', 'AI Compatibility', Icons.psychology, gamesState.activeTab, gamesNotifier),
                  const SizedBox(width: 8),
                  _buildTabChip('trivia', 'Vibe Trivia', Icons.emoji_events, gamesState.activeTab, gamesNotifier),
                  const SizedBox(width: 8),
                  _buildTabChip('truth_dare', 'Truth or Dare', Icons.local_fire_department, gamesState.activeTab, gamesNotifier),
                  const SizedBox(width: 8),
                  _buildTabChip('quest', 'City Quest', Icons.compass_calibration, gamesState.activeTab, gamesNotifier),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            if (gamesState.activeTab == 'trivia') _buildTriviaCard(gamesState),
            if (gamesState.activeTab == 'quiz') _buildQuizCard(),
            if (gamesState.activeTab == 'truth_dare') _buildTruthDareCard(),
            if (gamesState.activeTab == 'quest') _buildQuestCard(gamesState, gamesNotifier),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplayerHeader(GamesState state, GamesNotifier notifier) {
    final matches = state.availableMatches;
    final activeSession = state.activeSession;

    if (activeSession != null) {
      final p1 = activeSession.participants.isNotEmpty ? activeSession.participants.first : null;
      final p2 = activeSession.participants.length > 1 ? activeSession.participants[1] : null;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.callBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.coral.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.circle, color: AppColors.success, size: 8),
                    SizedBox(width: 6),
                    Text('Live Multiplayer Room', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  activeSession.status,
                  style: const TextStyle(color: AppColors.coralLight, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(p1?.displayName ?? 'You', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('${p1?.score ?? state.soloTriviaScore} pts', style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('VS', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
                Column(
                  children: [
                    Text(p2?.displayName ?? 'Match', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('${p2?.score ?? 0} pts', style: const TextStyle(color: AppColors.warning, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invite a Mutual Match to Play', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text('Compete live, answer trivia questions, and test your chemistry.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          if (matches.isEmpty)
            const Text('Match with someone in Discover first!', style: TextStyle(fontSize: 12, color: AppColors.coral))
          else
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: state.selectedMatchId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: matches.map((m) {
                      return DropdownMenuItem(value: m.id, child: Text(m.name, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setSelectedMatchId(val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: state.isLoading || state.selectedMatchId == null
                      ? null
                      : () {
                          final typeMap = {
                            'quiz': 'COMPATIBILITY_QUIZ',
                            'trivia': 'VIBE_CHECK',
                            'truth_dare': 'TRUTH_OR_DARE',
                            'quest': 'TREASURE_RACE',
                          };
                          notifier.sendGameInvitation(state.selectedMatchId!, typeMap[state.activeTab] ?? 'VIBE_CHECK');
                        },
                  child: const Text('Invite'),
                ),
              ],
            ),
          if (state.statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(state.statusMessage!, style: const TextStyle(fontSize: 11, color: AppColors.coral, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildTabChip(String key, String label, IconData icon, String activeKey, GamesNotifier notifier) {
    final isSelected = activeKey == key;
    return InkWell(
      onTap: () => notifier.setActiveTab(key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.coral : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.coral : AppColors.border),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.coral.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Trivia Card
  Widget _buildTriviaCard(GamesState state) {
    if (_triviaFinished) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Trivia Completed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text('You scored ${state.soloTriviaScore} / 100 points!', style: const TextStyle(fontSize: 14, color: AppColors.coral, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _triviaIndex = 0;
                    _selectedTriviaOpt = null;
                    _triviaFinished = false;
                  });
                },
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      );
    }

    final q = _triviaQuestions[_triviaIndex];
    final opts = q['opts'] as List<String>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question ${_triviaIndex + 1} of ${_triviaQuestions.length}', style: const TextStyle(fontSize: 12, color: AppColors.coral, fontWeight: FontWeight.bold)),
                Text('${state.soloTriviaScore} pts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning)),
              ],
            ),
            const SizedBox(height: 12),
            Text(q['q'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink, height: 1.3)),
            const SizedBox(height: 18),
            ...List.generate(opts.length, (idx) {
              final isSelected = _selectedTriviaOpt == idx;
              final isCorrect = idx == q['correct'];
              Color bgColor = Colors.white;
              Color borderColor = AppColors.border;

              if (_selectedTriviaOpt != null) {
                if (isCorrect) {
                  bgColor = AppColors.successSoft;
                  borderColor = AppColors.success;
                } else if (isSelected) {
                  bgColor = AppColors.errorSoft;
                  borderColor = AppColors.error;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _handleTriviaAnswer(idx),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Text(
                      opts[idx],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _selectedTriviaOpt != null && isCorrect ? AppColors.success : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (_selectedTriviaOpt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('💡 ${q['fact']}', style: const TextStyle(fontSize: 12, color: AppColors.coralDark)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 2. Compatibility Quiz Card
  Widget _buildQuizCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: AppColors.coral),
                SizedBox(width: 8),
                Text('AI Compatibility Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Answer personality dilemmas to update your chemistry vector and discover higher-match singles.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scenario: Your ideal Saturday evening', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  SizedBox(height: 10),
                  Text('A. Cosy book café with artisanal chai', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('B. Live indie gig and bustling street food', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('C. Sunset walk along historic park arches', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✨ Compatibility neural vector updated! +20 Sparks')),
                );
              },
              child: const Text('Submit Quiz Answers'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Truth or Dare Card
  Widget _buildTruthDareCard() {
    final prompt = _isTruth
        ? _truthPrompts[_tdPromptIndex % _truthPrompts.length]
        : _darePrompts[_tdPromptIndex % _darePrompts.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.coral),
                    const SizedBox(width: 6),
                    Text(
                      _isTruth ? 'Truth Prompt' : 'Dare Prompt',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Truth', style: TextStyle(fontSize: 11)),
                      selected: _isTruth,
                      onSelected: (val) => setState(() => _isTruth = true),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Dare', style: TextStyle(fontSize: 11)),
                      selected: !_isTruth,
                      onSelected: (val) => setState(() => _isTruth = false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.coral.withOpacity(0.2)),
              ),
              child: Text(
                '“$prompt”',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.coralDark, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _tdPromptIndex++),
                  icon: const Icon(Icons.refresh, size: 16, color: AppColors.coral),
                  label: const Text('Next Prompt', style: TextStyle(color: AppColors.coral, fontSize: 12)),
                ),
              ],
            ),
            TextField(
              controller: _tdController,
              decoration: const InputDecoration(hintText: 'Write your answer or response…'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _tdController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Response shared with your match!')),
                );
              },
              child: const Text('Share Response'),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Quest Card
  Widget _buildQuestCard(GamesState state, GamesNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.compass_calibration, color: AppColors.coral),
                    SizedBox(width: 8),
                    Text('Treasure Race Quest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(10)),
                  child: Text('Stage ${state.questStep + 1} of 3', style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clue: The Courtyard Reader’s Quest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  SizedBox(height: 6),
                  Text(
                    '“Seek the leafy courtyard where old pages turn beside steaming cardamom chai in Hauz Khas Village.”',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 8),
                  Text('Reward: Virtual Coffee Cup ☕ (+50 pts)', style: TextStyle(fontSize: 11, color: AppColors.coralDark, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                notifier.advanceQuest();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 Riddle Solved! Reward added to Collectibles.')),
                );
              },
              child: const Text('Solve & Claim Reward'),
            ),
          ],
        ),
      ),
    );
  }
}
