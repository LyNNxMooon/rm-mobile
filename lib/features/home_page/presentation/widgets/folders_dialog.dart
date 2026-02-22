import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rmstock_scanner/entities/vos/network_server_vo.dart';
import 'package:rmstock_scanner/features/home_page/presentation/widgets/shopfronts_dialog.dart';
import 'package:rmstock_scanner/utils/log_utils.dart';
import 'package:rmstock_scanner/utils/navigation_extension.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../../../constants/colors.dart';
import '../../../../constants/global_widgets.dart';
import '../../../../constants/txt_styles.dart';
import '../../../../utils/dependency_injection_utils.dart';
import '../../domain/use_cases/check_if_shopfront_file_exists.dart';
import '../BLoC/home_screen_bloc.dart';
import '../BLoC/home_screen_events.dart';
import '../BLoC/home_screen_states.dart';

class FoldersDialog extends StatefulWidget {
  const FoldersDialog({super.key, required this.pc, this.previousPath = ""});

  final NetworkServerVO pc;
  final String previousPath;

  @override
  State<FoldersDialog> createState() => _FoldersDialogState();
}

class _FoldersDialogState extends State<FoldersDialog> {
  final useCaseOfCheckingIfShopfrontFileExists = CheckIfShopfrontFileExists(
    sl(),
  );

  Future<void> _handleFolderSelection(
    String path, {
    String? username,
    String? password,
  }) async {
    logger.d("UI folder tracking: $path / $username / $password");

    await useCaseOfCheckingIfShopfrontFileExists(
      widget.pc.ipAddress,
      path,
      username,
      password,
    ).then((isShopfront) {
      if (mounted) {
        if (isShopfront) {
          context.read<ConnectingFolderBloc>().add(
            ConnectToFolderEvent(
              ipAddress: widget.pc.ipAddress,
              hostName: widget.pc.hostName,
              path: path,
              userName: username,
              pwd: password,
            ),
          );
        } else {
          setState(() {
            _currentPath = path;
          });

          context.read<GettingDirectoryBloc>().add(
            GetDirectoryEvent(
              ipAddress: widget.pc.ipAddress,
              path: path,
              userName: username,
              pwd: password,
            ),
          );
        }
      }
    });
  }

  late String _currentPath;

  final _userNameController = TextEditingController();
  final _pwdController = TextEditingController();

  @override
  void initState() {
    _currentPath = widget.previousPath;
    super.initState();
  }

  @override
  void dispose() {
    if (!mounted) {
      _userNameController.dispose();
      _pwdController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic height calculation
    final double safeMaxHeight = MediaQuery.of(context).size.height * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 10,
      backgroundColor: kBgColor,
      child: Container(
        // Responsive constraints
        constraints: BoxConstraints(maxHeight: safeMaxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: kGColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.folder_solid,
                    color: Colors.yellow,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Select a Folder",
                      style: getSmartTitle(fontSize: 16),
                      maxLines: 1, // Prevent header overflow
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (_currentPath.isEmpty) {
                        context.navigateBack();
                      } else {
                        List<String> parts = _currentPath.split('/');
                        parts.removeLast();
                        String parentPath = parts.join('/');

                        setState(() {
                          _currentPath = parentPath;
                        });

                        context.read<GettingDirectoryBloc>().add(
                          GetDirectoryEvent(
                            ipAddress: widget.pc.ipAddress,
                            path: _currentPath,
                          ),
                        );
                      }
                    },
                    child: const Icon(
                      CupertinoIcons.arrow_turn_down_left,
                      size: 24,
                      color: kSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: BlocBuilder<GettingDirectoryBloc, GettingDirectoryStates>(
                builder: (context, state) {
                  if (state is GettingDirectory) {
                    return const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CupertinoActivityIndicator()),
                    );
                  } else if (state is DirectoryLoaded) {
                    if (state.directList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text("No folders shared on this server."),
                      );
                    }

                    List<String> direct = state.directList;

                    if (_currentPath.isEmpty &&
                        state.directList.contains("AAAPOS RM-Mobile")) {
                      direct.remove("AAAPOS RM-Mobile");
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: direct.length,
                      separatorBuilder: (ctx, i) => Divider(
                        color: kGreyColor.withOpacity(0.2),
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) =>
                          _buildFolderTile(direct[index], context),
                    );
                  } else if (state is ErrorGettingDirectory) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      // SingleChildScrollView prevents keyboard overflow
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: kErrorColor,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kGreyColor),
                            ),
                            const SizedBox(height: 20),
                            // Safe Container usage
                            SizedBox(
                              height: 45, // Slightly increased for touch safety
                              child: CustomTextField(
                                hintText: 'UserName',
                                controller: _userNameController,
                                leadingIcon: Icons.people,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 45,
                              child: CustomTextField(
                                hintText: 'Password',
                                controller: _pwdController,
                                leadingIcon: Icons.password,
                              ),
                            ),
                            const SizedBox(height: 25),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _handleFolderSelection(_currentPath),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: kPrimaryColor.withOpacity(0.5),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12, // Increased padding
                                        ),
                                      ),
                                      child: Text(
                                        "Retry as Guest",
                                        style: TextStyle(
                                          color: kPrimaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _handleFolderSelection(
                                        _currentPath,
                                        username: _userNameController.text,
                                        password: _pwdController.text,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        foregroundColor: kSecondaryColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text(
                                        "Try Logging in",
                                        style: TextStyle(
                                          color: kSecondaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            BlocListener<ConnectingFolderBloc, ConnectingFolderStates>(
              listener: (context, state) {
                if (state is FolderConnected) {
                  AlertInfo.show(
                    context: context,
                    text: state.message,
                    typeInfo: TypeInfo.success,
                    backgroundColor: kSecondaryColor,
                    iconColor: kPrimaryColor,
                    textColor: kThirdColor,
                    position: MessagePosition.top,
                    padding: 70,
                  );

                  context.navigateUntilFirst();

                  context.read<ShopfrontBloc>().add(
                    FetchShops(
                      ipAddress: widget.pc.ipAddress,
                      path: state.path,

                      userName: _userNameController.text,
                      pwd: _pwdController.text,
                    ),
                  );
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return ShopfrontsDialog(
                        pc: widget.pc,
                        previousPath: state.path,
                      );
                    },
                  );
                }

                if (state is ErrorConnectingFolder) {
                  showTopSnackBar(
                    Overlay.of(context),
                    CustomSnackBar.error(message: state.message),
                  );
                }
              },
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTile(String direct, BuildContext ctx) {
    return InkWell(
      onTap: () async {
        String targetPath = _currentPath.isEmpty
            ? direct
            : "$_currentPath/$direct";

        logger.d("UI SF Path: $targetPath");

        await _handleFolderSelection(
          targetPath,
          username: _userNameController.text,
          password: _pwdController.text,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.folder_fill,
              size: 22,
              color: Colors.yellow,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                direct,
                style: const TextStyle(
                  color: kThirdColor,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1, // Fix list overflow
                overflow: TextOverflow.ellipsis,
              ),
            ),
            BlocBuilder<ConnectingFolderBloc, ConnectingFolderStates>(
              builder: (_, state) {
                if (state is ConnectingFolder &&
                    state.lastDirect == direct.split('/').last) {
                  return const CupertinoActivityIndicator();
                } else {
                  return const Icon(
                    Icons.arrow_forward_ios,
                    color: kGreyColor,
                    size: 14,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
