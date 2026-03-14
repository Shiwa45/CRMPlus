import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:henox/controller/my_controller.dart';
import 'package:henox/helpers/services/auth_service.dart';
import 'package:henox/helpers/widgets/my_form_validator.dart';

class LoginController extends MyController {
  bool rememberMe = false;
  MyFormValidator basicValidator = MyFormValidator();

  @override
  void onInit() {
    basicValidator.addField('username',
        required: true,
        label: "Username",
        validators: [],
        controller: TextEditingController(text: 'henox'));

    basicValidator.addField('password',
        required: true,
        label: "Password",
        validators: [],
        controller: TextEditingController(text: '123456789'));
    super.onInit();
  }

  void rememberToggle() {
    rememberMe = !rememberMe;
    update();
  }

  Future<void> onLogin() async {
    if (basicValidator.validateForm()) {
      update();
      var errors = await AuthService.loginUser(basicValidator.getData());
      if (errors != null) {
        basicValidator.addErrors(errors);
        basicValidator.validateForm();
        basicValidator.clearErrors();
      } else {
        String nextUrl =
            Uri.parse(ModalRoute.of(Get.context!)?.settings.name ?? "")
                    .queryParameters['next'] ??
                "/dashboard";
        Get.toNamed(nextUrl);
      }
      update();
    }
  }

  void gotoForgotPasswordScreen() {
    Get.toNamed('/auth/forgot_password');
  }

  void goToRegisterScreen() {
    Get.toNamed('/auth/register_account');
  }
}
