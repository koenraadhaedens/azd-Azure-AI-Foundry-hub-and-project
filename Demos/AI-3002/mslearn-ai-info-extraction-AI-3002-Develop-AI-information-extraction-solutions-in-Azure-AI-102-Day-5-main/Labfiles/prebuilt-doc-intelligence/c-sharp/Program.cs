using Azure;
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
                string key = configuration["KEY"];

                // Set analysis settings
                Uri fileUri = new Uri("https://github.com/MicrosoftLearning/mslearn-ai-information-extraction/blob/main/Labfiles/prebuilt-doc-intelligence/sample-invoice/sample-invoice.pdf?raw=true");

                Console.WriteLine("\nConnecting to Forms Recognizer at: {0}", endpoint);
                Console.WriteLine("Analyzing invoice at: {0}\n", fileUri.ToString());



                // Create the client


                // Analyze the invoice


                // Display invoice information to the user


                
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }

            Console.WriteLine("\nAnalysis complete.\n");
        }
    }
}

            
