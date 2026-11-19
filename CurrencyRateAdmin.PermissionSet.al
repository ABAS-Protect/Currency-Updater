/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-11-19
    Description: Update currencies daily via ExchangeRate-API.
*/

namespace ABAS.ABAS_Currency_Updater;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;

permissionset 50101 "Currency Rate Admin"
{
    Assignable = true;
    Caption = 'Live Currency Rate Administration';

    Permissions =
        codeunit "Live Currency Rate Updater" = X,
        page "ExchangeRate API Key Dialog" = X,
        tabledata Currency = R,
        tabledata "General Ledger Setup" = R,
        tabledata "Currency Exchange Rate" = RIM;
}