enum MarcaTarjeta { mastercard, visa }

class TarjetaGuardada {
  const TarjetaGuardada({
    this.id,
    required this.marca,
    required this.ultimosDigitos,
    required this.expira,
    this.principal = false,
  });

  final String? id;
  final MarcaTarjeta marca;
  final String ultimosDigitos;
  final String expira;
  final bool principal;

  factory TarjetaGuardada.fromJson(Map<String, dynamic> json) => TarjetaGuardada(
    id: json['id']?.toString(),
    marca: json['marca']?.toString() == 'mastercard' ? MarcaTarjeta.mastercard : MarcaTarjeta.visa,
    ultimosDigitos: json['ultimosDigitos']?.toString() ?? '',
    expira: json['expira']?.toString() ?? '',
    principal: json['principal'] == true,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'marca': marca.name,
    'ultimosDigitos': ultimosDigitos,
    'expira': expira,
    'principal': principal,
  };

  TarjetaGuardada copyWith({bool? principal}) => TarjetaGuardada(
    id: id,
    marca: marca,
    ultimosDigitos: ultimosDigitos,
    expira: expira,
    principal: principal ?? this.principal,
  );
}
