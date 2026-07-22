import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/pedido_admin.dart';

const _colorPrimario = PdfColor.fromInt(0xFF1565C0);
const _colorGris = PdfColor.fromInt(0xFF616161);

/// Arma el ticket de un pedido en tamaño angosto (como un recibo de punto de
/// venta), listo para el diálogo de impresión nativo.
Future<Uint8List> generarTicketPdf(PedidoAdmin pedido) async {
  final doc = pw.Document();
  const anchoTicket = PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);

  doc.addPage(
    pw.Page(
      pageFormat: anchoTicket,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'FreshClean',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _colorPrimario),
            ),
          ),
          pw.Center(
            child: pw.Text('Ticket de pedido', style: const pw.TextStyle(fontSize: 9, color: _colorGris)),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          _fila('Pedido', pedido.numero),
          _fila('Fecha', pedido.fecha),
          _fila('Cliente', pedido.clienteNombre),
          _fila('Teléfono', pedido.clienteTelefono),
          _fila('Servicio', pedido.servicioNombre),
          _fila('Estado', estadoToString(pedido.estado)),
          if (pedido.repartidorNombre != null) _fila('Repartidor', pedido.repartidorNombre!),
          pw.Divider(),
          pw.Text('Detalle', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          for (final item in pedido.items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text(item.nombre, style: const pw.TextStyle(fontSize: 9))),
                  pw.Text('\$${item.precio.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                pedido.precioConfirmado ? 'Total confirmado' : 'Total estimado',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '\$${pedido.precioFinal.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _colorPrimario),
              ),
            ],
          ),
          if (pedido.metodoPago != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('Pagado con ${pedido.metodoPago}', style: const pw.TextStyle(fontSize: 9, color: _colorGris)),
          ],
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text('¡Gracias por elegir FreshClean!', style: const pw.TextStyle(fontSize: 9, color: _colorGris)),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

pw.Widget _fila(String etiqueta, String valor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 55,
          child: pw.Text(etiqueta, style: const pw.TextStyle(fontSize: 9, color: _colorGris)),
        ),
        pw.Expanded(
          child: pw.Text(valor, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    ),
  );
}
