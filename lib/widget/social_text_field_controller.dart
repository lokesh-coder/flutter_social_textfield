import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_textfield/controller/social_text_editing_controller.dart';

class DefaultSocialTextFieldController extends StatefulWidget {

  final FocusNode focusNode;
  final ScrollController? scrollController;
  final SocialTextEditingController textEditingController;
  final Widget child;
  final Map<DetectedType, PreferredSize Function(BuildContext context)>? detectionBuilders;

  DefaultSocialTextFieldController({required this.child,required this.textEditingController,required this.focusNode, this.detectionBuilders,this.scrollController});

  @override
  _DefaultSocialTextFieldControllerState createState() => _DefaultSocialTextFieldControllerState();
}

class _DefaultSocialTextFieldControllerState extends State<DefaultSocialTextFieldController> {

  bool willShowDetectionContent = false;
  DetectedType _detectedType = DetectedType.plain_text;

  StreamSubscription<SocialContentDetection>? _streamSubscription;

  Map<DetectedType, double> heightMap = Map();

  var animationDuration = const Duration(milliseconds: 200);

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _streamSubscription = widget.textEditingController.subscribeToDetection(onDetectContent);
    DetectedType.values.forEach((type) {
      if (widget.detectionBuilders?[type] != null) {
        heightMap[type] = widget.detectionBuilders?[type]!(context).preferredSize.height ?? 0;
      } else {
        heightMap[type] = 0;
      }
    });
    print("HeightMap: $heightMap");
  }

  void onDetectContent(SocialContentDetection detection){
    print("detection");
    if(detection.type != _detectedType){
      print("new detection");
      setState(() {
        _detectedType = detection.type;
      });
      print(" does have ${doesHaveBuilderForCurrentType()}");
      if(doesHaveBuilderForCurrentType() && widget.scrollController != null){

        var baseText = widget.textEditingController.text.substring(0,widget.textEditingController.selection.baseOffset);
        var defaultTextStyle = TextStyle();
        if(widget.textEditingController.detectionTextStyles.containsKey(DetectedType.plain_text)){
          defaultTextStyle = widget.textEditingController.detectionTextStyles[DetectedType.plain_text]!;
        }
        var estimatedSize = getTextRectSize(width: widget.focusNode.size.width, text: baseText, style: defaultTextStyle);
        print("will scroll: $estimatedSize");
        Future.delayed(animationDuration,()=>widget.scrollController?.animateTo(estimatedSize.height, duration: Duration(milliseconds: 200), curve: Curves.easeInOut));
      }
    }
  }

  Size getTextRectSize({required width,required String text,required TextStyle style}) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: width);
    return textPainter.size;
  }

  bool doesHaveBuilderForCurrentType(){
    return (widget.detectionBuilders?.containsKey(_detectedType) ?? false);
  }

  double getChildBottomHeight(){
    if(!doesHaveBuilderForCurrentType()){
      return 0;
    }
    print("${heightMap[_detectedType] ?? 0}");
    return heightMap[_detectedType] ?? 0;
  }

  PreferredSize getDetectionContent(){
    if(!(widget.detectionBuilders?.containsKey(_detectedType) ?? false)){
      return PreferredSize(child: Container(), preferredSize: Size.zero);
    }
    return widget.detectionBuilders?[_detectedType]!(context) ?? PreferredSize(child: Container(), preferredSize: Size.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: animationDuration,
          top: 0,
          left: 0,
          right: 0,
          bottom: getChildBottomHeight(),
          child: widget.child),
        AnimatedPositioned(
          duration: animationDuration,
          bottom: 0,
          left: 0,
          right: 0,
          height: getChildBottomHeight(),
          child: getDetectionContent())
      ],
    );
  }
}