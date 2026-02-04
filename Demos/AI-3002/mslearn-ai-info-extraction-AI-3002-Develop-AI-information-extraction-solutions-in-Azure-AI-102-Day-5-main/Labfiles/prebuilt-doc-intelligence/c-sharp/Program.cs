using Azure;
using Azure.Identity;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

// Add references


namespace document_analysis
{
    class Program
    {
        static async Task Main(string[] args)
        {
            // Clear the console
            Console.Clear();

            try
            {
                // Get config settings
                IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("appsettings.json");
                IConfigurationRoot configuration = builder.Build();
                string endpoint = configuration["ENDPOINT"];

                // Use managed identity for authentication
                var credential = new DefaultAzureCredential();

                // Set analysis settings
                Uri fileUri = new Uri("https://github.com/MicrosoftLearning/mslearn-ai-information-extraction/blob/main/Labfiles/prebuilt-doc-intelligence/sample-invoice/sample-invoice.pdf?raw=true");

                Console.WriteLine("\nConnecting to Forms Recognizer at: {0}", endpoint);
                Console.WriteLine("Analyzing invoice at: {0}\n", fileUri.ToString());

                // Create the client
                var client = new DocumentAnalysisClient(new Uri(endpoint), credential);

                // Analyse the invoice
                AnalyzeDocumentOperation operation = await client.AnalyzeDocumentFromUriAsync(
                    WaitUntil.Completed,
                    "prebuilt-invoice", fileUri);

                // Display invoice information to the user
                AnalyzeResult result = operation.Value;

                foreach (AnalyzedDocument invoice in result.Documents)
                {
                    if (invoice.Fields.TryGetValue("VendorName", out DocumentField? vendorNameField))
                    {
                        if (vendorNameField.FieldType == DocumentFieldType.String)
                        {
                            string vendorName = vendorNameField.Value.AsString();
                            Console.WriteLine($"Vendor Name: '{vendorName}', with confidence {vendorNameField.Confidence}.");
                        }
                    }

                    if (invoice.Fields.TryGetValue("CustomerName", out DocumentField? customerNameField))
                    {
                        if (customerNameField.FieldType == DocumentFieldType.String)
                        {
                            string customerName = customerNameField.Value.AsString();
                            Console.WriteLine($"Customer Name: '{customerName}', with confidence {customerNameField.Confidence}.");
                        }
                    }

                    if (invoice.Fields.TryGetValue("InvoiceTotal", out DocumentField? invoiceTotalField))
                    {
                        if (invoiceTotalField.FieldType == DocumentFieldType.Currency)
                        {
                            CurrencyValue invoiceTotal = invoiceTotalField.Value.AsCurrency();
                            Console.WriteLine($"Invoice Total: '{invoiceTotal.Symbol}{invoiceTotal.Amount}', with confidence {invoiceTotalField.Confidence}.");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }

            Console.WriteLine("\nAnalysis complete.\n");
        }
    }
}


