<?php

namespace App\Filament\Resources\Transactions\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;
use Illuminate\Database\Eloquent\Builder;

class TransactionForm
{
  public static function configure(Schema $schema): Schema
  {
    return $schema->schema([
      Select::make('wallet_id')
        ->label('Wallet')
        ->relationship(
          name: 'wallet',
          titleAttribute: 'name',
          modifyQueryUsing: function (Builder $query) {
            $query->where(
              'workspace_id',
              auth()->user()->current_workspace_id
            );
          }
        )
        ->searchable()->required(),

      Select::make('category_id')
        ->label('Category')
        ->relationship(
          name: 'category',
          titleAttribute: 'name',
          modifyQueryUsing: function (Builder $query) {
            $query->where(
              'workspace_id',
              auth()->user()->current_workspace_id
            );
          }
        )->searchable()->required(),

        
      TextInput::make('amount')
        ->numeric()
        ->required(),

      DatePicker::make('transaction_date')
        ->default(now())
        ->required(),

      Textarea::make('description')
        ->columnSpanFull(),
    ]);
  }
}
