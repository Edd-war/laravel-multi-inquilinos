<?php

namespace Eddwar\Multitenencia;

use Illuminate\Support\Facades\Facade;

class MultitenenciaFacade extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return Multitenencia::class;
    }
}
