import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gplx/features/home/models/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_state.freezed.dart';

@freezed
class HomeState with _$HomeState {
  factory HomeState({
    @Default(0) int number,
    @Default(AsyncValue.loading()) AsyncValue<List<Post>> postList,
  }) = _HomeState;
}
