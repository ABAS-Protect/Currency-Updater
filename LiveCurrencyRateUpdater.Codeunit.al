/*
    Author: Niklas Dougherty <nd@abas.se>
    Date: 2026-11-19
    Description: Update currencies daily via ExchangeRate-API.
*/

namespace ABAS.ABAS_Currency_Updater;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Threading;

codeunit 50116 "Live Currency Rate Updater"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        this.UpdateLiveExchangeRates();
    end;

    procedure UpdateLiveExchangeRates()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        Client: HttpClient;
        Response: HttpResponseMessage;
        JsonResponse: JsonObject;
        RatesToken: JsonToken;
        RatesObject: JsonObject;
        RateToken: JsonToken;
        ResponseText: Text;
        BaseCurrency: Code[10];
        ExternalRate: Decimal;
        ApiUrl: Text;
        ApiKey: Text;
        URLMsg: Label 'https://v6.exchangerate-api.com/v6/', Locked = true;
        CurrencyErr: Label 'Local Currency (LCY Code) must be defined in General Ledger Setup.';
        ConnectErr: Label 'Failed to connect to the currency exchange rate API.';
        ParseErr: Label 'Failed to parse JSON response from currency API.';
        HttpStatusErr: Label 'API returned HTTP status %1: %2', Comment = '%1 = HTTP Status Code, %2 = Reason Phrase';
        ResponseErr: Label 'JSON response does not contain a "conversion_rates" object.';
        MissingApiKeyErr: Label 'ExchangeRate-API key is not configured. Please set it in Currencies setup.';
    begin
        GLSetup.Get();
        BaseCurrency := GLSetup."LCY Code";
        if BaseCurrency = '' then
            Error(CurrencyErr);

        ApiKey := DelChr(this.GetApiKey(), '<>', ' ');
        if ApiKey = '' then
            Error(MissingApiKeyErr);

        ApiUrl := URLMsg + ApiKey + '/latest/' + BaseCurrency;

        Client.DefaultRequestHeaders().Add('Accept', 'application/json');
        if not Client.Get(ApiUrl, Response) then
            Error(ConnectErr);

        if not Response.IsSuccessStatusCode() then
            Error(HttpStatusErr, Response.HttpStatusCode(), Response.ReasonPhrase());

        Response.Content().ReadAs(ResponseText);
        if not JsonResponse.ReadFrom(ResponseText) then
            Error(ParseErr);

        if not JsonResponse.Get('conversion_rates', RatesToken) then
            Error(ResponseErr);

        RatesObject := RatesToken.AsObject();

        if Currency.FindSet() then
            repeat
                if (Currency.Code <> BaseCurrency) and RatesObject.Get(Currency.Code, RateToken) then begin
                    ExternalRate := RateToken.AsValue().AsDecimal();
                    if ExternalRate <> 0 then
                        this.UpsertCurrencyExchangeRate(Currency.Code, Today(), ExternalRate);
                end;
            until Currency.Next() = 0;
    end;

    [NonDebuggable]
    procedure SetApiKey(NewApiKey: Text)
    begin
        if NewApiKey = '' then begin
            if IsolatedStorage.Contains(this.GetStorageKeyName(), DataScope::Company) then
                IsolatedStorage.Delete(this.GetStorageKeyName(), DataScope::Company);
        end else
            IsolatedStorage.Set(this.GetStorageKeyName(), NewApiKey, DataScope::Company);
    end;

    [NonDebuggable]
    local procedure GetApiKey(): Text
    var
        ApiKey: Text;
    begin
        if IsolatedStorage.Get(this.GetStorageKeyName(), DataScope::Company, ApiKey) then
            exit(ApiKey);
        exit('');
    end;

    local procedure GetStorageKeyName(): Text
    begin
        exit('ExchangeRateApi_Key');
    end;

    local procedure UpsertCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ApiRate: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
        InvertedRate: Decimal;
    begin
        InvertedRate := Round(1 / ApiRate, 0.000001);

        if CurrExchRate.Get(CurrencyCode, StartingDate) then begin
            CurrExchRate.Validate("Exchange Rate Amount", 1);
            CurrExchRate.Validate("Relational Exch. Rate Amount", InvertedRate);
            CurrExchRate.Validate("Adjustment Exch. Rate Amount", 1);
            CurrExchRate.Validate("Relational Adjmt Exch Rate Amt", InvertedRate);
            CurrExchRate.Modify(true);
        end else begin
            CurrExchRate.Init();
            CurrExchRate.Validate("Currency Code", CurrencyCode);
            CurrExchRate.Validate("Starting Date", StartingDate);
            CurrExchRate.Validate("Exchange Rate Amount", 1);
            CurrExchRate.Validate("Relational Exch. Rate Amount", InvertedRate);
            CurrExchRate.Validate("Adjustment Exch. Rate Amount", 1);
            CurrExchRate.Validate("Relational Adjmt Exch Rate Amt", InvertedRate);
            CurrExchRate.Insert(true);
        end;
    end;
}