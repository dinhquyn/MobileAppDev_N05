import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../data/model/song.dart';
import 'audio_player_manager.dart';
import '../../data/provider/favorite_provider.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key, required this.playingSong, required this.songs});
  final Song playingSong;
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return NowPlayingPage(
      songs: songs,
      playingSong: playingSong,
    );
  }
}

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({
    super.key,
    required this.songs,
    required this.playingSong,});

  final Song playingSong;
  final List<Song> songs;

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}
//Text header
class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimController;
  late AudioPlayerManager _audioPlayerManager;
  late int _selectedItemIndex;
  late Song _song;
  late double _currentAnimationPosition = 0.0;
  bool _isShuffle = false;
  late LoopMode _loopMode;
  final double delta = 64;
  double radius = 0;
  double screenWidth = 0;

  @override
  void initState(){
    super.initState();
    _currentAnimationPosition = 0.0;
    _song = widget.playingSong;
    _imageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _audioPlayerManager = AudioPlayerManager();
    
    // Cập nhật kích thước sau khi build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          screenWidth = MediaQuery.of(context).size.width;
          radius = (screenWidth - delta) / 2;
        });
      }
    });
    
    // Thêm listener để tự động chuyển bài
    _audioPlayerManager.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_loopMode == LoopMode.one) {
          _audioPlayerManager.player.seek(Duration.zero);
          _audioPlayerManager.player.play();
        } else {
          _setNextSong();
        }
      }
    });
    
    if(_audioPlayerManager.songUrl.compareTo(_song.source) != 0) {
      _audioPlayerManager.updateSongUrl(_song.source);
      _audioPlayerManager.prepare(isNewSong: true);
    } else {
      _audioPlayerManager.prepare(isNewSong: false);
    }
    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
    _loopMode = LoopMode.off;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text(
              'Now Playing',
            ),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz),
            ),
          ),
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_song.album),
                  const SizedBox
                    (height: 16,
                  ),
                  const Text('_ ___ _'),
                  const SizedBox(
                    height: 48,
                  ),
                  RotationTransition(turns: Tween(begin: 0.0, end: 1.0).animate(_imageAnimController),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/ITunes_logo.svg.png',
                        image: _song.image,
                        width: screenWidth - delta,
                        height: screenWidth - delta,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Image.asset('assets/ITunes_logo.svg.png',
                            width: screenWidth - delta,
                            height: screenWidth - delta,
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 64, bottom: 16),
                    child: SizedBox(child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(onPressed: () {},
                          icon: const Icon(Icons.share_outlined),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Column(
                          children: [
                            Text(
                              _song.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color),
                            ),
                            const  SizedBox(height: 8,),
                            Text(
                              _song.artist,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color),
                            )
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            favoriteProvider.toggleFavorite(_song);
                            _showSnackBar(
                              context,
                              favoriteProvider.isFavorite(_song)
                                  ? 'Đã thêm "${_song.title}" vào danh sách yêu thích'
                                  : 'Đã xóa "${_song.title}" khỏi danh sách yêu thích',
                            );
                          },
                          icon: Icon(
                            favoriteProvider.isFavorite(_song) 
                                ? Icons.favorite 
                                : Icons.favorite_outline
                          ),
                          color: favoriteProvider.isFavorite(_song)
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                        )
                      ],
                    ),),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      left: 24,
                      right: 24,
                      bottom: 10,
                    ),
                    child: _progressBar(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      left: 24,
                      right: 24,
                      bottom: 10,
                    ),
                    child: _mediaButtons(),
                  )
                ],
              ),
            ),
          )
        );
      }
    );
  }

  @override
  void dispose() {
    _imageAnimController.dispose();
    // Đảm bảo hủy listener khi widget bị dispose
    _audioPlayerManager.player.playerStateStream.drain();
    super.dispose();
  }


  Widget _mediaButtons() {
    return  SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MediaButtonControl(
              function: _setShuffle,
              icon: Icons.shuffle,
              color: _getShuffleColor(),
              size: 24),
          MediaButtonControl(
              function: _setPrevSong,
              icon: Icons.skip_previous,
              color: Colors.deepPurple,
              size: 36),
          _playButton(),
          MediaButtonControl(
              function: _setNextSong,
              icon: Icons.skip_next,
              color: Colors.deepPurple,
              size: 36),
          MediaButtonControl(
              function: _setupRepeatOption,
              icon: _repeatingIcon(),
              color: _getRepeatingIconColor(),
              size: 24),
        ],
      ),
    );
  }
  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          total: total,
          buffered: buffered,
          onSeek: _audioPlayerManager.player.seek,
          barHeight: 5.0,
          barCapShape: BarCapShape.round,
          baseBarColor: Colors.grey.withOpacity(0.3),
          progressBarColor: Colors.green,
          bufferedBarColor: Colors.grey.withOpacity(0.3),
          thumbColor: Colors.deepPurple,
          thumbGlowColor: Colors.green.withOpacity(0.3),
          thumbRadius: 10.0,


        );
      },
    );
  }
  StreamBuilder<PlayerState> _playButton(){
    return StreamBuilder(
      stream: _audioPlayerManager.player.playerStateStream,
      builder: (context, snapshot) {
        final playState = snapshot.data;
        final processingSate = playState?.processingState;
        final playing = playState?.playing;
        if(processingSate == ProcessingState.loading ||
            processingSate == ProcessingState.buffering){
          _pauseRotationAnim();
          return Container(
            margin: const EdgeInsets.all(8),
            width: 48,
            height: 48,
            child: const CircularProgressIndicator(),
          );
        } else if(playing != true) {
          return MediaButtonControl(
            function: () {
            _audioPlayerManager.player.play();
          },
            icon: Icons.play_arrow,
            color: Colors.deepPurple,
            size: 48,
          );
        } else if(processingSate != ProcessingState.completed) {
          _playRotationAnim();
          return MediaButtonControl(
            function: () {
            _audioPlayerManager.player.pause();
            _pauseRotationAnim();
          },
            icon: Icons.pause,
            color: Colors.deepPurple,
            size: 48,
          );
        } else {
          if(processingSate == ProcessingState.completed){
            _stopRotationAnim();
            _resetRotationAnim();
          }
          return MediaButtonControl(
            function:(){
              _audioPlayerManager.player.seek(Duration.zero);
              _resetRotationAnim();
              _playRotationAnim();
            },
            icon: Icons.replay,
            color: null,
            size: 48,
          );
        }
      },
    );
  }

  void _setShuffle() {
    setState(() {
      _isShuffle = ! _isShuffle;
    });
  }
  Color? _getShuffleColor() {
    return _isShuffle ? Colors.deepPurple : Colors.grey;
  }

  void _setNextSong() {
    if(_isShuffle) {
      var random = Random();
      _selectedItemIndex = random.nextInt(widget.songs.length);
    } else if(_selectedItemIndex < widget.songs.length - 1) {
      ++_selectedItemIndex;
    } else if (_loopMode == LoopMode.all && _selectedItemIndex == widget.songs.length -1){
      _selectedItemIndex = 0;
    }
    
    if(_selectedItemIndex >= widget.songs.length) {
      _selectedItemIndex = _selectedItemIndex % widget.songs.length;
    }
    
    final nextSong = widget.songs[_selectedItemIndex];
    setState(() {
      _song = nextSong;
      _audioPlayerManager.updateSongUrl(nextSong.source);
      _audioPlayerManager.prepare(isNewSong: true);
      _resetRotationAnim();
      // Tự động phát bài hát mới
      _audioPlayerManager.player.play();
    });
  }

  void _setPrevSong() {
    if(_isShuffle) {
      var random = Random();
      _selectedItemIndex = random.nextInt(widget.songs.length);
    } else if(_selectedItemIndex > 0) {
      --_selectedItemIndex;
    } else if(_loopMode == LoopMode.all && _selectedItemIndex == 0) {
      _selectedItemIndex = widget.songs.length - 1;
    }
    
    if(_selectedItemIndex < 0) {
      _selectedItemIndex = widget.songs.length - 1;
    }
    
    final prevSong = widget.songs[_selectedItemIndex];
    setState(() {
      _song = prevSong;
      _audioPlayerManager.updateSongUrl(prevSong.source);
      _audioPlayerManager.prepare(isNewSong: true);
      _resetRotationAnim();
      // Tự động phát bài hát mới
      _audioPlayerManager.player.play();
    });
  }

  void _setupRepeatOption() {
    if(_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if(_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    setState(() {
      _audioPlayerManager.player.setLoopMode(_loopMode);
    });
  }


  IconData _repeatingIcon() {
    return switch(_loopMode) {
      LoopMode.one => Icons.repeat_one,
      LoopMode.all => Icons.repeat_on,
      _ => Icons.repeat,
    };
  }

  Color? _getRepeatingIconColor() {
    return _loopMode == LoopMode.off
        ? Colors.grey
        : Colors.deepPurple;
  }

  void _playRotationAnim(){
    _imageAnimController.forward(from: _currentAnimationPosition);
    _imageAnimController.repeat();

  }

  void _pauseRotationAnim(){
    _stopRotationAnim();
    _currentAnimationPosition = _imageAnimController.value;

  }

  void _stopRotationAnim() {
    _imageAnimController.stop();
  }

  void _resetRotationAnim() {
    _currentAnimationPosition = 0.0;
    _imageAnimController.value = _currentAnimationPosition;
  }
}

class MediaButtonControl extends StatefulWidget {
  const MediaButtonControl({
    super.key,
    required this.function,
    required this.icon,
    required this.color,
    required this. size,
  });

  final void Function()? function;
  final IconData icon;
  final double? size;
  final Color? color;


  @override
  State<StatefulWidget> createState() => _MediaButtonControlState();

}
class _MediaButtonControlState extends State<MediaButtonControl> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.function,
      icon: Icon(widget.icon),
      iconSize: widget.size,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
