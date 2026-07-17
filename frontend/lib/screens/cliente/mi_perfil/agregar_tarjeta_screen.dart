import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/tarjeta.dart';
import '../../../utils/app_colors.dart';

class _NumeroTarjetaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final entrada = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digitos = entrada.length > 16 ? entrada.substring(0, 16) : entrada;
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitos[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiracionFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final entrada = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digitos = entrada.length > 4 ? entrada.substring(0, 4) : entrada;
    final texto = digitos.length > 2
        ? '${digitos.substring(0, 2)}/${digitos.substring(2)}'
        : digitos;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

class AgregarTarjetaScreen extends StatefulWidget {
  const AgregarTarjetaScreen({super.key});

  @override
  State<AgregarTarjetaScreen> createState() => _AgregarTarjetaScreenState();
}

class _AgregarTarjetaScreenState extends State<AgregarTarjetaScreen> {
  final _nombreController = TextEditingController();
  final _numeroController = TextEditingController();
  final _expiracionController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _esPrincipal = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nombreController,
      _numeroController,
      _expiracionController,
      _cvvController,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numeroController.dispose();
    _expiracionController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  /// Valida que el MM/AA tenga un mes real (01-12) y que la tarjeta no
  /// esté ya vencida respecto a la fecha actual.
  bool get _expiracionValida {
    final texto = _expiracionController.text;
    if (texto.length != 5) return false;

    final partes = texto.split('/');
    if (partes.length != 2) return false;

    final mes = int.tryParse(partes[0]);
    final anio = int.tryParse(partes[1]);
    if (mes == null || anio == null) return false;
    if (mes < 1 || mes > 12) return false;

    final finDeVigencia = DateTime(2000 + anio, mes + 1);
    return finDeVigencia.isAfter(DateTime.now());
  }

  bool get _formularioValido =>
      _nombreController.text.trim().isNotEmpty &&
      _numeroController.text.replaceAll(' ', '').length == 16 &&
      _expiracionValida &&
      _cvvController.text.length >= 3;

  void _guardarTarjeta() {
    setState(() => _isLoading = true);
    final digitos = _numeroController.text.replaceAll(' ', '');
    final marca = digitos.startsWith('4')
        ? MarcaTarjeta.visa
        : MarcaTarjeta.mastercard;
    Navigator.of(context).pop(
      TarjetaGuardada(
        marca: marca,
        ultimosDigitos: digitos.substring(digitos.length - 4),
        expira: _expiracionController.text,
        principal: _esPrincipal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Añadir Tarjeta',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TarjetaPreview(
                nombre: _nombreController.text,
                numero: _numeroController.text,
                expiracion: _expiracionController.text,
              ),
              const SizedBox(height: 32),
              _CampoFormulario(
                etiqueta: 'Nombre del Titular',
                icon: Icons.person_outline_rounded,
                controller: _nombreController,
                hint: 'ej. Juan Pérez',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              _CampoFormulario(
                etiqueta: 'Número de Tarjeta',
                icon: Icons.credit_card_rounded,
                controller: _numeroController,
                hint: '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                inputFormatters: [_NumeroTarjetaFormatter()],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CampoFormulario(
                          etiqueta: 'Fecha de Expiración',
                          icon: Icons.calendar_month_rounded,
                          controller: _expiracionController,
                          hint: 'MM/AA',
                          keyboardType: TextInputType.number,
                          inputFormatters: [_ExpiracionFormatter()],
                        ),
                        if (_expiracionController.text.length == 5 && !_expiracionValida)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              'Fecha inválida o vencida',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CampoFormulario(
                      etiqueta: 'CVV',
                      icon: Icons.lock_outline_rounded,
                      controller: _cvvController,
                      hint: '123',
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Establecer como principal',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            'Usar para todos los pedidos futuros',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _esPrincipal,
                      activeThumbColor: AppColors.primary,
                      onChanged: (valor) =>
                          setState(() => _esPrincipal = valor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_formularioValido && !_isLoading)
                      ? _guardarTarjeta
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.outlineVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.save_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Guardar Tarjeta',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Conexión segura y encriptada',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaPreview extends StatelessWidget {
  const _TarjetaPreview({
    required this.nombre,
    required this.numero,
    required this.expiracion,
  });

  final String nombre;
  final String numero;
  final String expiracion;

  @override
  Widget build(BuildContext context) {
    final ultimosDigitos = numero.replaceAll(' ', '');
    final sufijo = ultimosDigitos.length >= 4
        ? ultimosDigitos.substring(ultimosDigitos.length - 4)
        : ultimosDigitos.padLeft(4, '*');

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.sensors_rounded,
                  color: Colors.white70,
                  size: 28,
                ),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-8, 0),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '**** **** **** $sufijo',
                  style: GoogleFonts.robotoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TITULAR',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          nombre.isEmpty ? 'Nombre Apellido' : nombre,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRA',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          expiracion.isEmpty ? 'MM/AA' : expiracion,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoFormulario extends StatelessWidget {
  const _CampoFormulario({
    required this.etiqueta,
    required this.icon,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String etiqueta;
  final IconData icon;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            prefixIcon: Icon(icon, color: AppColors.outline, size: 20),
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.outlineVariant,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
