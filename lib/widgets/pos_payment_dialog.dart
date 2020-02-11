import 'dart:async';

import 'package:breez/bloc/invoice/invoice_bloc.dart';
import 'package:breez/bloc/user_profile/breez_user_model.dart';
import 'package:breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:breez/services/countdown.dart';
import 'package:breez/theme_data.dart' as theme;
import 'package:breez/widgets/compact_qr_image.dart';
import 'package:flutter/material.dart';

enum _PosPaymentState { WAITING_FOR_PAYMENT, PAYMENT_RECEIVED }

class _PosPaymentDialogState extends State<PosPaymentDialog> {
  _PosPaymentState _state = _PosPaymentState.WAITING_FOR_PAYMENT;
  CountDown _paymentTimer;
  StreamSubscription<Duration> _timerSubscription;
  String _countdownString = "3:00";
  String _debugMessage = "";

  StreamSubscription<String> _sentInvoicesSubscription;
  StreamSubscription<bool> _paidInvoicesSubscription;
  StreamSubscription<BreezUserModel> _userProfileSubscription;

  @override
  void initState() {
    super.initState();

    _userProfileSubscription =
        widget._userProfileBloc.userStream.asBroadcastStream().listen((user) {
      _paymentTimer =
          CountDown(Duration(seconds: user.cancellationTimeoutValue.toInt()));
      _timerSubscription = _paymentTimer.stream.listen(null);
      _timerSubscription.onData((Duration d) {
        setState(() {
          _countdownString = d.inMinutes.toRadixString(10) +
              ":" +
              (d.inSeconds - (d.inMinutes * 60))
                  .toRadixString(10)
                  .padLeft(2, '0');
        });
      });

      _timerSubscription.onDone(() {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(false);
        }
      });

      _timerSubscription.onData((Duration d) {
        setState(() {
          _countdownString = d.inMinutes.toRadixString(10) +
              ":" +
              (d.inSeconds - (d.inMinutes * 60))
                  .toRadixString(10)
                  .padLeft(2, '0');
        });
      });

      _timerSubscription.onDone(() {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(false);
        }
      });
    });

    _sentInvoicesSubscription =
        widget._invoiceBloc.sentInvoicesStream.listen((message) {
      _debugMessage = message;

      setState(() {
        _state = _PosPaymentState.WAITING_FOR_PAYMENT;
      });
    }, onError: (err) {
      Navigator.of(context).pop(false);
      widget._scaffoldKey.currentState.showSnackBar(SnackBar(
          duration: Duration(seconds: 3), content: Text(err.toString())));
    });

    _paidInvoicesSubscription =
        widget._invoiceBloc.paidInvoicesStream.listen((paid) {
      setState(() {
        _state = _PosPaymentState.PAYMENT_RECEIVED;
      });
    }, onError: (err) {
      Navigator.of(context).pop(false);
      widget._scaffoldKey.currentState.showSnackBar(SnackBar(
          duration: Duration(seconds: 3), content: Text(err.toString())));
    });
  }

  @override
  void dispose() {
    _timerSubscription?.cancel();
    _paidInvoicesSubscription?.cancel();
    _sentInvoicesSubscription?.cancel();
    _userProfileSubscription?.cancel();
    super.dispose();
  }

  Widget _cancelButton() {
    return FlatButton(
      padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Text(
        'CANCEL PAYMENT',
        textAlign: TextAlign.center,
        style: theme.cancelButtonStyle,
      ),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.fromLTRB(40.0, 28.0, 40.0, 0.0),
      content: SingleChildScrollView(
          child: _state == _PosPaymentState.WAITING_FOR_PAYMENT
              ? ListBody(
                  children: <Widget>[
                    _buildDialogBody(
                        'Scan the QR code to process this payment.',
                        StreamBuilder<String>(
                            stream: widget._invoiceBloc.readyInvoicesStream,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  height: 230.0,
                                  width: 230.0,
                                );
                              }
                              return AspectRatio(
                                  aspectRatio: 1.0,
                                  child: Container(
                                      height: 230.0,
                                      width: 230.0,
                                      child: AspectRatio(
                                          aspectRatio: 1.0,
                                          child: CompactQRImage(
                                            data: snapshot.data,
                                          ))));
                            })),
                    Padding(
                        padding: EdgeInsets.only(top: 15.0),
                        child: Text(_countdownString,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .primaryTextTheme
                                .display1
                                .copyWith(fontSize: 16))),
                    _cancelButton(),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(true);
                  },
                  child: ListBody(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 40.0),
                        child: Text(
                          'Payment approved!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .primaryTextTheme
                              .display1
                              .copyWith(fontSize: 16),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(bottom: 40.0),
                          child: ImageIcon(
                            AssetImage("src/icon/ic_done.png"),
                            size: 48.0,
                            color: Color.fromRGBO(0, 133, 251, 1.0),
                          )),
                    ],
                  ),
                )),
    );
  }

  ListBody _buildDialogBody(String title, Widget body) {
    return ListBody(children: <Widget>[
      Text(
        title,
        textAlign: TextAlign.center,
        style:
            Theme.of(context).primaryTextTheme.display1.copyWith(fontSize: 16),
      ),
      Padding(
        padding: EdgeInsets.only(top: 15.0),
        child: body,
      )
    ]);
  }
}

class PosPaymentDialog extends StatefulWidget {
  final InvoiceBloc _invoiceBloc;
  final UserProfileBloc _userProfileBloc;

  final GlobalKey<ScaffoldState> _scaffoldKey;

  PosPaymentDialog(this._invoiceBloc, this._userProfileBloc, this._scaffoldKey);

  @override
  _PosPaymentDialogState createState() {
    return _PosPaymentDialogState();
  }
}
