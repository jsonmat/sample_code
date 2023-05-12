import 'dart:io';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  CroppedFile? _croppedFile;
  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    final darkMode = isDarkMode(context);
    final theme = Theme.of(context);
    return BasicLayout(
        padding: EdgeInsets.zero,
        titleText: "Settings",
        body: Consumer(
          builder: (context, ref, child) {
            final user = ref.watch(userDocProvider).value;
            final authState = ref.watch(authProvider);
            final userImage = user?.data()?.authProviderAvatar;
            final userAvatar = user?.data()?.avatar.original;

            String initials = "";
            initials = getInitials(authState.displayName);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      if (_isUploadingAvatar)
                        const StandardCircleAvatar(
                          width: 120,
                          height: 120,
                          child: LoadingSpinner(
                            size: 13,
                            strokeWidth: 1.5,
                          ),
                        ),
                      if (!_isUploadingAvatar)
                        StandardCircleAvatar(
                          width: 120,
                          height: 120,
                          foregroundImage: userAvatar?.isNotEmpty == true
                              ? NetworkImage(userAvatar!)
                              : (_croppedFile != null
                                  ? Image.file(File(_croppedFile!.path)).image
                                  : (userImage?.isNotEmpty == true
                                      ? NetworkImage(userImage!)
                                      : null)),
                          child: Text(initials),
                        ),
                      Positioned(
                        bottom: 0.0,
                        right: 0.0,
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {
                              showModalBottomSheet<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    height: userAvatar?.isNotEmpty == true
                                        ? 190
                                        : 140,
                                    child: ListView(
                                      children: <Widget>[
                                        ListTile(
                                          leading: const Icon(
                                              Icons.camera_alt_rounded),
                                          title: const Text('Camera'),
                                          onTap: () async {
                                            Navigator.of(context).pop();
                                            try {
                                              final XFile? pickedFile =
                                                  await _picker.pickImage(
                                                      source:
                                                          ImageSource.camera);
                                              if (pickedFile != null) {
                                                if (user != null) {
                                                  _cropImage(
                                                      pickedFile.path, user.id);
                                                }
                                              }
                                            } catch (e) {
                                              AdviiseToast.error(e.toString());
                                            }
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.photo),
                                          title:
                                              const Text('Pick from gallery'),
                                          onTap: () async {
                                            Navigator.of(context).pop();
                                            try {
                                              final XFile? pickedFile =
                                                  await _picker.pickImage(
                                                      source:
                                                          ImageSource.gallery);
                                              if (pickedFile != null) {
                                                if (user != null) {
                                                  _cropImage(
                                                      pickedFile.path, user.id);
                                                }
                                              }
                                            } catch (e) {
                                              AdviiseToast.error(e.toString());
                                            }
                                          },
                                        ),
                                        Visibility(
                                          visible:
                                              userAvatar?.isNotEmpty == true,
                                          child: ListTile(
                                            leading: const Icon(Icons.delete),
                                            title: const Text(
                                                'Remove profile picture'),
                                            onTap: () async {
                                              Navigator.of(context).pop();
                                              if (user != null) {
                                                await deleteAvatar();
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                              backgroundColor:
                                  AdviiseColors.primary, // <-- Button color
                              foregroundColor:
                                  AdviiseColors.secondary, // <-- Splash color
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  user?.data()?.name ?? "",
                  textAlign: TextAlign.center,
                  style: AdviiseFonts.serif(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: theme.colorScheme.onBackground),
                ),
                const SizedBox(
                  height: 20,
                ),
                SettingsButtonGroup(
                  labelText: "Account",
                  children: [
                    SettingsButton(
                        titleText: "Profile",
                        icon: const Icon(Icons.account_circle),
                        iconColor: theme.colorScheme.onSurface,
                        iconBackgroundColor: theme.colorScheme.surface,
                        onPressed: () => Navigator.push(
                              context,
                              slideInRoute(
                                const SettingsProfileScreen(),
                              ),
                            )),
                    SettingsButton(
                      titleText: "Password & Security",
                      icon: const Icon(Icons.lock),
                      iconColor: darkMode
                          ? theme.colorScheme.background
                          : AdviiseColors.secondary.shade900,
                      iconBackgroundColor: darkMode
                          ? AdviiseColors.secondary
                          : AdviiseColors.secondary.shade100,
                      onPressed: () => Navigator.push(
                        context,
                        slideInRoute(
                          const SettingsSecurityScreen(),
                        ),
                      ),
                    ),
                    SettingsButton(
                        titleText: "Linked Accounts",
                        icon: const Icon(
                          Icons.link,
                        ),
                        iconColor: theme.colorScheme.background,
                        iconBackgroundColor: theme.colorScheme.onSecondary,
                        onPressed: () => Navigator.push(
                              context,
                              slideInRoute(
                                const SettingsLinkAccountsScreen(),
                              ),
                            )),
                    authState.emailIsVerified
                        ? SettingsButton(
                            titleText: "Email Verified",
                            icon: const Icon(Icons.check),
                            iconColor: darkMode
                                ? AdviiseColors.white
                                : AdviiseColors.success.shade600,
                            iconBackgroundColor: darkMode
                                ? AdviiseColors.success.shade600
                                : AdviiseColors.success.shade100,
                            onPressed: () {
                              AdviiseToast.success(
                                  "This email has already been verified");
                            },
                          )
                        : SettingsButton(
                            titleText: "Email Not Verified",
                            subtitleText: "Click to send verification email",
                            icon: const Icon(Icons.close),
                            iconColor: darkMode
                                ? AdviiseColors.white
                                : AdviiseColors.danger.shade600,
                            iconBackgroundColor: darkMode
                                ? AdviiseColors.danger.shade600
                                : AdviiseColors.danger.shade100,
                            onPressed: () {
                              // TODO
                              // Send email verification email
                            },
                          ),
                    SettingsButton(
                        titleText: "Delete Account",
                        iconColor: darkMode
                            ? AdviiseColors.white
                            : AdviiseColors.danger.shade900,
                        iconBackgroundColor: darkMode
                            ? AdviiseColors.danger.shade900
                            : AdviiseColors.danger.shade100,
                        onPressed: () {
                          Navigator.push(
                              context,
                              slideInRoute(
                                  const SettingsDeleteAccountScreen()));
                        },
                        icon: const Icon(Icons.delete)),
                    SettingsButton(
                        titleText: "Logout",
                        icon: const Icon(Icons.logout),
                        iconColor: darkMode
                            ? AdviiseColors.white
                            : AdviiseColors.danger.shade600,
                        iconBackgroundColor: darkMode
                            ? AdviiseColors.danger.shade600
                            : AdviiseColors.danger.shade100,
                        onPressed: () async {
                          try {
                            final nav = Navigator.of(context);
                            var provider = ref.read(authProvider.notifier);
                            await provider.signUserOut();
                            nav.pushAndRemoveUntil(
                                BasicRoute(const LoginScreen()), (_) => false);
                          } on FirebaseAuthException catch (err) {
                            AdviiseToast.error(err.message.toString());
                          } catch (err) {
                            AdviiseToast.error(err.toString());
                          }
                        }),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                SettingsButtonGroup(
                  labelText: "Other",
                  children: [
                    SettingsButton(
                      titleText: "About this App",
                      icon: const Icon(Icons.info),
                      onPressed: () {
                        Navigator.push(
                            context,
                            slideInRoute(const SettingsAboutScreen(),
                                transitionDirection:
                                    TransitionDirections.left));
                      },
                    ),
                    SettingsButton(
                      titleText: "Privacy Policy",
                      icon: const Icon(Icons.shield),
                      onPressed: () async {
                        await launchUrlString(
                            "https://adviise.com/policies/privacy-policy/");
                      },
                    ),
                    SettingsButton(
                      titleText: "Legal",
                      icon: const Icon(Icons.list),
                      onPressed: () {
                        Navigator.push(
                            context, slideInRoute(const SettingsLegalScreen()));
                      },
                    )
                  ],
                )
              ],
            );
          },
        ));
  }

  Future<void> _cropImage(String path, String uid) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      compressQuality: 80,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
            ]
          : [
              CropAspectRatioPreset.square,
            ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop image',
            toolbarColor: AdviiseColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        IOSUiSettings(
          title: 'Crop image',
        )
      ],
    );
    if (croppedFile != null) {
      uploadAvatar(uid, croppedFile);
    }
  }

  Future<void> uploadAvatar(String uid, CroppedFile croppedFile) async {
    AdviiseToast.info('Uploading your profile picture...');
    final storageRef = FirebaseStorage.instance.ref();
    final avatarRef = storageRef.child("users/avatars/$uid/avatar.jpg");
    int statusCode = 401;
    try {
      setState(() {
        _isUploadingAvatar = true;
      });
      final uploadTask =
          await avatarRef.putFile(File(croppedFile.path)).then((res) => res);
      String url = await uploadTask.ref.getDownloadURL();
      statusCode = await ref.read(authProvider.notifier).updateUserAvatar(url);
      if (statusCode == 200) {
        AdviiseToast.success('You have successfully set your profile picture.');
      } else {
        AdviiseToast.error('Something went wrong. Status code: $statusCode');
      }
    } on FirebaseException catch (e) {
      AdviiseToast.error(e.message!);
    }
    setState(() {
      if (statusCode == 200) {
        _croppedFile = croppedFile;
      }
      _isUploadingAvatar = false;
    });
  }

  Future<void> deleteAvatar() async {
    AdviiseToast.info('Removing your profile picture...');
    try {
      await ref.read(authProvider.notifier).removeUserAvatar();
      setState(() {
        _croppedFile = null;
      });
      AdviiseToast.success(
          'You have successfully removed your profile picture.');
    } on FirebaseException catch (e) {
      AdviiseToast.error(e.message!);
    }
  }
}

class SettingsButtonGroup extends StatelessWidget {
  final String? labelText;
  final TextStyle? labelTextStyle;
  final Iterable<Widget> children;
  const SettingsButtonGroup(
      {Key? key, this.children = const [], this.labelText, this.labelTextStyle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Visibility(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(labelText ?? "",
                style: labelTextStyle ??
                    AdviiseFonts.sans(fontWeight: FontWeight.bold)),
            const SizedBox(
              height: 10,
            )
          ],
        )),
        ...children
      ],
    );
  }
}

class SettingsButton extends StatelessWidget {
  final String titleText;
  final String? subtitleText;
  final Function()? onPressed;
  final Widget icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const SettingsButton(
      {Key? key,
      required this.titleText,
      this.subtitleText,
      this.onPressed,
      required this.icon,
      this.iconColor,
      this.iconBackgroundColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          foregroundColor: iconColor,
          backgroundColor: iconBackgroundColor ?? AdviiseColors.gray.shade50,
          child: icon,
        ),
        title: Text(titleText),
        subtitle: subtitleText is String ? Text(subtitleText!) : null,
      ),
    );
  }
}
