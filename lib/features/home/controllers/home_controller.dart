import 'package:gplx/features/home/controllers/home_state.dart';
import 'package:gplx/features/home/data/home_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  HomeState build() {
    fetchPost();

    return HomeState();
  }

  Future<void> fetchPost() async {
    final asyncPosts = await ref.watch(homeRepoProvider.notifier).fetchPosts();
    // await ref.watch(homeRepoProvider.notifier).postWithError(); // try return API error
    state = state.copyWith(postList: asyncPosts);
  }

  FutureOr<void> fetchDetail({required int userId}) async {
    final asyncPosts = await ref
        .read(homeRepoProvider.notifier)
        .fetchPostDetail(userId: userId);

    state = state.copyWith(postList: asyncPosts);
    return null;
  }

  void increment() => state = state.copyWith(number: state.number + 1);
  void decrement() => state = state.copyWith(number: state.number - 1);
}
