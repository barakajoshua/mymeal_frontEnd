import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String contactInfo; // The phone number or email being verified
  final VoidCallback onVerified;

  const OtpVerificationDialog({
    super.key,
    required this.contactInfo,
    required this.onVerified,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (value.length > 1) {
         _handlePaste(value);
         return;
      }
      
      // If just one digit entered, move next.
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      // Backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _handlePaste(String value) {
    String code = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (code.length > 4) code = code.substring(0, 4);

    for (int i = 0; i < code.length; i++) {
        _controllers[i].text = code[i];
    }
    
    // Focus appropriate field
    if (code.length == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[3].unfocus();
      });
    } else if (code.isNotEmpty) {
       _focusNodes[code.length < 4 ? code.length : 3].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       backgroundColor: Colors.white,
       elevation: 0,
       child: Padding(
         padding: const EdgeInsets.all(24.0),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text(
               "Verification Code",
               style: TextStyle(
                 fontWeight: FontWeight.bold,
                 fontSize: 20,
                 fontFamily: 'comfortaa',
               ),
             ),
             const SizedBox(height: 15),
             Text(
               "We have sent a verification code on ${widget.contactInfo} paste it this input to contue changing the email or phone",
               textAlign: TextAlign.center,
               style: const TextStyle(
                 color: Colors.grey,
                 fontSize: 14,
                 fontFamily: 'comfortaa',
               ),
             ),
             const SizedBox(height: 30),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: List.generate(4, (index) {
                 return SizedBox(
                   width: 50,
                   height: 60,
                   child: TextField(
                     controller: _controllers[index],
                     focusNode: _focusNodes[index],
                     keyboardType: TextInputType.number,
                     textAlign: TextAlign.center,
                     style: const TextStyle(
                       fontSize: 24, 
                       fontWeight: FontWeight.bold,
                       fontFamily: 'comfortaa',
                     ),
                     decoration: InputDecoration(
                       counterText: "",
                       filled: true,
                       fillColor: Colors.grey[100],
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(10),
                         borderSide: BorderSide.none,
                       ),
                       focusedBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(10),
                         borderSide: const BorderSide(color: Color(0xFF32B768), width: 2),
                       ),
                     ),
                     onChanged: (value) => _onChanged(value, index),
                     inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4), // Allow up to 4 to catch paste, logic will trim
                     ],
                   ),
                 );
               }),
             ),
             const SizedBox(height: 30),
             SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: () {
                   // Verify logic here (dummy for now)
                   widget.onVerified();
                   Navigator.pop(context);
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF32B768),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(15),
                   ),
                 ),
                 child: const Text(
                   "Verify",
                   style: TextStyle(
                     color: Colors.white, 
                     fontWeight: FontWeight.bold,
                     fontFamily: 'comfortaa',
                   ),
                 ),
               ),
             ),
           ],
         ),
       ),
    );
  }
}
