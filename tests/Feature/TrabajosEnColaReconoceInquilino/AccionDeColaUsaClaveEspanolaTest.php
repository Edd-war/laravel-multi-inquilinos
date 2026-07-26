<?php

use Eddwar\Multitenencia\Actions\AccionHacerColaInquilinoReconocido;
use Eddwar\Multitenencia\Exceptions\ExcepcionConfiguracionNoValida;
use Eddwar\Multitenencia\Multitenencia;
use Eddwar\Multitenencia\Tests\TestCase;

it('usa la clave española accion_hacer_cola_inquilino_reconocido de la configuración', function () {
    /** @var TestCase $this */
    $accionEjecutada = false;

    // Crear una acción personalizada que extiende AccionHacerColaInquilinoReconocido
    $accionPersonalizada = new class extends AccionHacerColaInquilinoReconocido
    {
        public bool $ejecutada = false;

        public function execute(): void
        {
            $this->ejecutada = true;
            parent::execute();
        }
    };

    // Registrar la acción personalizada en la clave española
    app()->instance(get_class($accionPersonalizada), $accionPersonalizada);
    config()->set('multitenencia.acciones.accion_hacer_cola_inquilino_reconocido', get_class($accionPersonalizada));

    // Re-iniciar Multitenencia para que use la config actualizada
    app(Multitenencia::class)->start();

    expect($accionPersonalizada->ejecutada)->toBeTrue();
});

it('lanza ExcepcionConfiguracionNoValida si la clase configurada no extiende AccionHacerColaInquilinoReconocido', function () {
    /** @var TestCase $this */
    config()->set('multitenencia.acciones.accion_hacer_cola_inquilino_reconocido', stdClass::class);

    expect(fn () => app(Multitenencia::class)->start())
        ->toThrow(ExcepcionConfiguracionNoValida::class);
});
