import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/corte_caja.dart';
import '../models/pedido_admin.dart';

const _colorPrimario = PdfColor.fromInt(0xFF1565C0);
const _colorGris = PdfColor.fromInt(0xFF616161);
const _colorGrisClaro = PdfColor.fromInt(0xFFE0E0E0);

String _fecha(DateTime fecha) {
  const meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
}

/// Arma el PDF del corte de caja de un día: ingresos, conteos por estado y
/// desglose por método de pago, más el listado de pedidos de ese día.
Future<Uint8List> generarCortePdf(CorteCaja corte) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'FreshClean',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _colorPrimario),
              ),
              pw.Text(
                'Corte de Caja',
                style: pw.TextStyle(fontSize: 14, color: _colorGris),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(_fecha(corte.fecha), style: const pw.TextStyle(fontSize: 12, color: _colorGris)),
          pw.Divider(color: _colorGrisClaro),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: _colorGris),
        ),
      ),
      build: (context) => [
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            _tarjetaResumen('Ingresos del día', '\$${corte.ingresosTotales.toStringAsFixed(2)}'),
            pw.SizedBox(width: 12),
            _tarjetaResumen('Pedidos recibidos', '${corte.pedidosRecibidos}'),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            _tarjetaResumen('Pedidos entregados', '${corte.pedidosEntregados}'),
            pw.SizedBox(width: 12),
            _tarjetaResumen('En proceso', '${corte.pedidosEnProceso}'),
            pw.SizedBox(width: 12),
            _tarjetaResumen('Cancelados', '${corte.pedidosCancelados}'),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Desglose por método de pago',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _colorPrimario),
        ),
        pw.SizedBox(height: 8),
        if (corte.porMetodoPago.isEmpty)
          pw.Text('Sin pagos registrados este día.', style: const pw.TextStyle(fontSize: 11, color: _colorGris))
        else
          pw.Table(
            border: pw.TableBorder.all(color: _colorGrisClaro),
            columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1)},
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _colorGrisClaro),
                children: [
                  _celda('Método de pago', negrita: true),
                  _celda('Total', negrita: true, alinDerecha: true),
                ],
              ),
              for (final entrada in corte.porMetodoPago.entries)
                pw.TableRow(children: [
                  _celda(entrada.key),
                  _celda('\$${entrada.value.toStringAsFixed(2)}', alinDerecha: true),
                ]),
            ],
          ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Pedidos del día (${corte.totalPedidos})',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _colorPrimario),
        ),
        pw.SizedBox(height: 8),
        if (corte.pedidos.isEmpty)
          pw.Text('No hubo pedidos este día.', style: const pw.TextStyle(fontSize: 11, color: _colorGris))
        else
          pw.Table(
            border: pw.TableBorder.all(color: _colorGrisClaro),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.3),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1.7),
              4: pw.FlexColumnWidth(1.3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _colorGrisClaro),
                children: [
                  _celda('Pedido', negrita: true),
                  _celda('Cliente', negrita: true),
                  _celda('Servicio', negrita: true),
                  _celda('Estado', negrita: true),
                  _celda('Total', negrita: true, alinDerecha: true),
                ],
              ),
              for (final p in corte.pedidos)
                pw.TableRow(children: [
                  _celda(p.numero),
                  _celda(p.clienteNombre),
                  _celda(p.servicioNombre),
                  _celda(estadoToString(p.estado)),
                  _celda('\$${p.precioFinal.toStringAsFixed(2)}', alinDerecha: true),
                ]),
            ],
          ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _tarjetaResumen(String etiqueta, String valor) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _colorGrisClaro),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(etiqueta, style: const pw.TextStyle(fontSize: 9, color: _colorGris)),
          pw.SizedBox(height: 4),
          pw.Text(valor, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _colorPrimario)),
        ],
      ),
    ),
  );
}

pw.Widget _celda(String texto, {bool negrita = false, bool alinDerecha = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(
      texto,
      textAlign: alinDerecha ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(fontSize: 9, fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal),
    ),
  );
}
