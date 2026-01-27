using Azure;
using System;
using System.Threading.Tasks;
using Azure.AI.FormRecognizer.DocumentAnalysis;
using Microsoft.Extensions.Configuration;

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

                // Get configuration settings from AppSettings
                IConfiguration configuration = new ConfigurationBuilder()
                    .AddJsonFile("appsettings.json")
                    .Build();
                string endpoint = configuration["DocIntelligenceEndpoint"];
                string apiKey = configuration["DocIntelligenceKey"];
                AzureKeyCredential credential = new AzureKeyCredential(apiKey);
                DocumentAnalysisClient client = new DocumentAnalysisClient(new Uri(endpoint), credential);

                string modelId =  configuration["ModelId"];
                Uri fileUri = new Uri("https://github.com/MicrosoftLearning/mslearn-ai-information-extraction/blob/main/Labfiles/custom-doc-intelligence/test1.jpg?raw=true");
                Console.WriteLine($"Analyzing document from Uri: {fileUri.AbsoluteUri}");

                AnalyzeDocumentOperation operation = await client.AnalyzeDocumentFromUriAsync(WaitUntil.Completed, modelId, fileUri);
                AnalyzeResult result = operation.Value;

                Console.WriteLine($"Document was analyzed with model with ID: {result.ModelId}");

                foreach (AnalyzedDocument document in result.Documents)
                {
                    Console.WriteLine($"Document of type: {document.DocumentType}");

                    foreach (KeyValuePair<string, DocumentField> fieldKvp in document.Fields)
                    {
                        string fieldName = fieldKvp.Key;
                        DocumentField field = fieldKvp.Value;

                        Console.WriteLine($"Field '{fieldName}': ");

                        Console.WriteLine($"  Content: '{field.Content}'");
                        Console.WriteLine($"  Confidence: '{field.Confidence}'");
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