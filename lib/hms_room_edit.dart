

class HmsRoomEditScreen extends ConsumerStatefulWidget {
  final String id;
  const HmsRoomEditScreen(this.id, {super.key});

  @override
  ConsumerState<HmsRoomEditScreen> createState() => _HmsRoomEditScreenState();
}

class _HmsRoomEditScreenState extends ConsumerState<HmsRoomEditScreen> {
  final formKey = GlobalKey<FormState>();
  bool isDeleting = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final roomDoc = ref.watch(roomDocProvider(widget.id));
    RoomInfoFormController? controller;

    Widget child = Container();

    roomDoc.when(loading: () {
      child = const Center(
        child: LoadingSpinner(),
      );
    }, error: ((error, stackTrace) {
      child = Center(
        child: Text("An error occurred: ${error.toString()}"),
      );
    }), data: (room) {
      controller ??= RoomInfoFormController(
          value: RoomInfoFormValue(
              name: room.data()?.name ?? "",
              isPermanent: room.data()?.isPermanent ?? false));
      child = RoomInfoForm(
        controller: controller,
      );
    });

    return BasicLayout(
      titleText: "Edit Room",
      body: child,
      bottomSheet: Container(
        constraints: const BoxConstraints(maxHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        color: Theme.of(context).backgroundColor,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: ButtonStandard(
              color: ButtonColor.danger,
              isLoading: isDeleting,
              onPressed: () async {
                final userConfirmsDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Are you sure?"),
                        content: const Text(
                            "Deleting this room is a permanent action"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text("No")),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text("Yes"))
                        ],
                      );
                    });
                if (userConfirmsDelete == true && mounted) {
                  setState(() {
                    isDeleting = true;
                  });
                  final nav = Navigator.of(context);
                  try {
                    await roomDocRef(widget.id).delete();
                    nav.pushAndRemoveUntil(
                        BasicRoute(const HmsRoomListScreen()),
                        (route) => false);
                    AdviiseToast.success("Room Deleted");
                    return;
                  } catch (err) {
                    AdviiseToast.error(err.toString());
                  }
                  setState(() {
                    isDeleting = false;
                  });
                }
              },
              child: const Text("Delete Room"),
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: ButtonStandard(
              isLoading: isSaving,
              onPressed: () async {
                final newRoom = roomDoc.value?.data()?.copyWith(
                    name: controller?.value.name,
                    isPermanent: controller?.value.isPermanent);
                if (newRoom != null) {
                  setState(() {
                    isSaving = true;
                  });
                  try {
                    await updateRoomDoc(roomDoc.value?.id ?? "", newRoom,
                        merge: true);
                    AdviiseToast.success("Info saved");
                  } catch (err) {
                    AdviiseToast.error(err.toString());
                  }
                  setState(() {
                    isSaving = false;
                  });
                }
              },
              child: const Text("Save Changes"),
            ),
          )
        ]),
      ),
    );
  }
}
