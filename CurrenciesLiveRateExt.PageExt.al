/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-11-19
    Description: Update currencies daily via ExchangeRate-API.
*/

namespace ABAS.ABAS_Currency_Updater;

using Microsoft.Finance.Currency;

pageextension 50112 "Currencies Live Rate Ext" extends Currencies
{
    actions
    {
        addlast(Processing)
        {
            action(SetExchangeRateApiKey)
            {
                ApplicationArea = All;
                Caption = 'Set ExchangeRate-API Key';
                Image = EncryptionKeys;
                ToolTip = 'Store or update the ExchangeRate-API key in encrypted isolated storage.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ApiKeyDialog: Page "ExchangeRate API Key Dialog";
                    SavedMsg: Label 'ExchangeRate-API key has been updated.';
                begin
                    if ApiKeyDialog.RunModal() = Action::OK then
                        Message(SavedMsg);
                end;
            }
            action(UpdateLiveRatesNow)
            {
                ApplicationArea = All;
                Caption = 'Update Live Exchange Rates';
                Image = CurrencyExchangeRates;
                ToolTip = 'Fetch the latest exchange rates from ExchangeRate-API immediately.';

                trigger OnAction()
                var
                    RateUpdater: Codeunit "Live Currency Rate Updater";
                    SuccessMsg: Label 'Live exchange rates have been updated for %1.', Comment = '%1 = Today Date';
                begin
                    RateUpdater.UpdateLiveExchangeRates();
                    Message(SuccessMsg, Today());
                end;
            }
        }
    }
}