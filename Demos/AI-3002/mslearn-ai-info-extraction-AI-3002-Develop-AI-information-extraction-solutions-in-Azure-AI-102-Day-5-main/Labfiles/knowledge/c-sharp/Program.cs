using System;
using Azure;
using System.Text;
using System.Collections.Generic;
using Microsoft.Extensions.Configuration;
using Azure.Identity;
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Models;


namespace search_app
{
    class Program
    {
        static void Main(string[] args)
        {
            // Clear the console
            Console.Clear();
            
            try
            {
                // Get config settings
                IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("appsettings.json");
                IConfigurationRoot configuration = builder.Build();
                string searchEndpoint = configuration["SEARCH_ENDPOINT"];
                string queryKey = configuration["QUERY_KEY"];
                string indexName = configuration["INDEX_NAME"];

                // Get a search client
                SearchClient searchClient = new SearchClient(
                                                        new Uri(searchEndpoint),
                                                        indexName,
                                                        new AzureKeyCredential(queryKey));

                // Loop until the user types 'quit'
                string queryText = "";
                while (queryText.ToLower() != "quit")
                {
                    // Get query text
                    Console.WriteLine("Enter a query (or type 'quit' to exit):");
                    queryText = Console.ReadLine() + "";
                    if (queryText.ToLower() != "quit")
                    {
                        // Clear the console
                        Console.Clear();

                        // Search the index
                        SearchOptions options = new SearchOptions
                        {
                            IncludeTotalCount = true
                        };
                        options.Select.Add("metadata_storage_name");
                        options.Select.Add("locations");
                        options.Select.Add("people");
                        options.Select.Add("keyphrases");
                        options.OrderBy.Add("metadata_storage_name");

                        SearchResults<Document> searchResults = searchClient.Search<Document>(queryText, options);

                        //Parse the results
                        Console.WriteLine($"\nSearch returned {searchResults.TotalCount} documents.");
                        foreach (SearchResult<Document> result in searchResults.GetResults())
                        {
                            Document doc = result.Document;
                            Console.WriteLine($"\n{doc.metadata_storage_name}:");
                            Console.WriteLine(" - Locations:");
                            foreach (string location in doc.locations)
                            {
                                Console.WriteLine($"   - {location}");
                            }
                            Console.WriteLine(" - People:");
                            foreach (string person in doc.people)
                            {
                                Console.WriteLine($"   - {person}");
                            }
                            Console.WriteLine(" - Key phrases:");
                            foreach (string phrase in doc.keyphrases)
                            {
                                Console.WriteLine($"   - {phrase}");
                            }
                        }

                        Console.WriteLine();

                    }

                }

            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
        }
    }

    public partial class Document
    {

        [SearchableField(IsFilterable=true, IsSortable=true)]
        public string metadata_storage_name { get; set; } = null!;

        [SearchableField(IsFilterable=true)]
        public string[] locations { get; set; } = null!;

        [SearchableField(IsFilterable=true)]
        public string[] people { get; set; } = null!;

        [SearchableField()]
        public string[] keyphrases { get; set; } = null!;

    }
}

