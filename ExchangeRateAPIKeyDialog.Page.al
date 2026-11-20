/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-11-19
    Description: Update currencies daily via ExchangeRate-API.
*/

namespace ABAS.ABAS_Currency_Updater;

page 50117 "ExchangeRate API Key Dialog"
{
    PageType = StandardDialog;
    Caption = 'Set ExchangeRate-API Key';

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                field(ApiKeyField; this.ApiKeyInput)
                {
                    ApplicationArea = All;
                    Caption = 'API Key';
                    ToolTip = 'Enter your ExchangeRate-API key.';
                    ExtendedDatatype = Masked;
                }
            }
        }
    }

    var
        [NonDebuggable]
        ApiKeyInput: Text;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RateUpdater: Codeunit "Live Currency Rate Updater";
    begin
        if CloseAction = Action::OK then
            RateUpdater.SetApiKey(this.ApiKeyInput);
        exit(true);
    end;
}