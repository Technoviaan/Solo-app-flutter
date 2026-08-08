import 'package:flutter/material.dart';
import 'notification_api.dart';

class ClearHistoryDialog extends StatefulWidget {
  const ClearHistoryDialog({super.key});

  @override
  State<ClearHistoryDialog> createState() => _ClearHistoryDialogState();
}

class _ClearHistoryDialogState extends State<ClearHistoryDialog> {

  bool loading = false;

  @override
  Widget build(BuildContext context) {

    return Dialog(

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFCDE047),
              child: Icon(Icons.delete),
            ),

            const SizedBox(height: 20),

            const Text(
              "Clear History",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),

            const SizedBox(height: 10),

            const Text(
              "Are you sure you want to clear your history?",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                OutlinedButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(

                  onPressed: loading ? null : () async {

                    setState(() {
                      loading = true;
                    });

                    final success =
                    await NotificationApi.clearCheckinHistory();

                    if(success){

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("History Cleared")),
                      );
                    }

                  },

                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Confirm"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}