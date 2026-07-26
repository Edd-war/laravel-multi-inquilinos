<?php

use Eddwar\Multitenencia\Multitenencia;
use Eddwar\Multitenencia\MultitenenciaFacade;

it('resuelve la fachada Multitenencia correctamente', function () {
    expect(MultitenenciaFacade::getFacadeRoot())->toBeInstanceOf(Multitenencia::class);
});

it('el alias Multitenencia en el contenedor apunta a la clase correcta', function () {
    expect(app(Multitenencia::class))->toBeInstanceOf(Multitenencia::class);
});
