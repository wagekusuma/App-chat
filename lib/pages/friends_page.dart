// ignore_for_file: camel_case_types, prefer_typing_uninitialized_variables

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatopia/core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FocusNode _focusNode = FocusNode();
  InternetStatus? internetStatus;
  StreamSubscription<InternetStatus>? listener;
  bool _isDone = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsProvider>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: value.isSearch
              ? searchAppBar(value)
              : AppBar(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Friends "),
                      Container(
                        decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            color: Colors.deepPurple.withOpacity(.1)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 5),
                          child: Text(
                            "${value.listFriends.length}",
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                        onPressed: () async {
                          value.isSearch = true;
                          _focusNode.requestFocus();
                        },
                        icon: const Icon(Icons.search)),
                    IconButton(
                        onPressed: () {
                          checkInternetAndGetFriends(context);
                        },
                        icon: const Icon(Icons.refresh)),
                    const SizedBox(width: 5),
                  ],
                ),
          body: WillPopScope(
            onWillPop: () async {
              if (value.isSearch) {
                value.searchController.clear();
                value.isSearch = false;
                return false;
              }
              return true;
            },
            child: internetStatus == InternetStatus.disconnected
                ? Center(
                    child: H5("no internet"),
                  )
                : value.loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : value.listFriends.isEmpty && _isDone
                        ? Center(
                            child: H5("Don't have friends"),
                          )
                        : value.listSearchFriends.isEmpty &&
                                value.searchController.text.isNotEmpty
                            ? Center(
                                child: H5("Not found"),
                              )
                            : ListView.builder(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: value.searchController.text.isEmpty
                                    ? value.listFriends.length
                                    : value.listSearchFriends.length,
                                itemBuilder: (context, i) {
                                  final data =
                                      value.searchController.text.isEmpty
                                          ? value.listFriends[i]
                                          : value.listSearchFriends[i];
                                  return ListTile(
                                    key: ValueKey(data['id']),
                                    onTap: () async {
                                      await checkInternetAndGetFriends(context);
                                      if (internetStatus ==
                                          InternetStatus.connected) {
                                        value.isSearch = false;
                                        Screen.pushNamedAndRemoveUntil(
                                            Routes.chats);
                                        Screen.toNamed(
                                          Routes.messages,
                                          arguments: {
                                            "room_id": data['room_id'],
                                            "friend_id": data['id'],
                                            "name": data['name'],
                                            "profile": data['profile'],
                                            "push_token": data['push_token'],
                                          },
                                        );
                                      } else {
                                        Get.fToastShow("No internet",
                                            gravity: ToastGravity.BOTTOM);
                                      }
                                    },
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 15,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 30,
                                      child: data['profile']!.isEmpty
                                          ? const Icon(Icons.person_rounded)
                                          : CachedNetworkImage(
                                              imageUrl: data['profile']!,
                                              fadeInCurve: Curves.easeIn,
                                              fadeOutCurve: Curves.easeOut,
                                              imageBuilder:
                                                  (context, imageProvider) =>
                                                      Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              placeholderFadeInDuration:
                                                  const Duration(
                                                      milliseconds: 100),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                    ),
                                    title: H4(
                                      data['name'],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    subtitle: Text(data['id']),
                                  );
                                },
                              ),
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    var provider = Provider.of<FriendsProvider>(context, listen: false);
    provider.searchController.clear();
    provider.listSearchFriends.clear();
    provider.listFriends.clear();
    updateIsDone(false);
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    Get.fToast.init(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkInternetAndGetFriends(context);
      updateIsDone(true);
    });
  }

  void updateIsDone(val) {
    setState(() {
      _isDone = val;
    });
  }

  Future checkInternetAndGetFriends(context) async {
    bool hasInternet = await InternetConnection().hasInternetAccess;
    var provider = Provider.of<FriendsProvider>(context, listen: false);
    if (hasInternet) {
      internetStatus = InternetStatus.connected;
      if (!provider.loading) {
        provider.getFriends();
      }
    } else {
      internetStatus = InternetStatus.disconnected;
      provider.listFriends.clear();
    }
    setState(() {});
  }

  AppBar searchAppBar(FriendsProvider value) {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          value.searchController.clear();
          value.isSearch = false;
        },
        icon: const Icon(Icons.arrow_back),
      ),
      title: TextFormField(
        keyboardType: TextInputType.text,
        controller: value.searchController,
        onChanged: value.search,
        focusNode: _focusNode,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'search name or id',
        ),
      ),
    );
  }
}
