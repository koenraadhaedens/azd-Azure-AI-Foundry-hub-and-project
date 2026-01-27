from dotenv import load_dotenv
import os

# Add references
from azure.identity import DefaultAzureCredential
from azure.ai.documentintelligence import DocumentIntelligenceClient
from azure.ai.documentintelligence.models import AnalyzeDocumentRequest



def main():

    # Clear the console
    os.system('cls' if os.name=='nt' else 'clear')

    try:
        # Get config settings
        load_dotenv()
        endpoint = os.getenv('ENDPOINT')

        # Use managed identity for authentication
        credential = DefaultAzureCredential()

        # Set analysis settings
        fileUri = "https://github.com/MicrosoftLearning/mslearn-ai-information-extraction/blob/main/Labfiles/prebuilt-doc-intelligence/sample-invoice/sample-invoice.pdf?raw=true"
        fileLocale = "en-US"
        fileModelId = "prebuilt-invoice"

        print(f"\nConnecting to Document Intelligence at: {endpoint}")
        print(f"Analyzing invoice at: {fileUri}")


        # Create the client using managed identity
        document_client = DocumentIntelligenceClient(
            endpoint=endpoint,
            credential=credential
        )

        # Analyse the invoice
        poller = document_client.begin_analyze_document(
            model_id=fileModelId,
            analyze_request=AnalyzeDocumentRequest(url_source=fileUri),
            locale=fileLocale
        )
        result = poller.result()

        # Display invoice information to the user
        for invoice in result.documents:
            print(f"\nInvoice details:")
            if invoice.fields:
                vendor_name = invoice.fields.get("VendorName")
                if vendor_name:
                    print(f"  Vendor: {vendor_name.content}")
                
                customer_name = invoice.fields.get("CustomerName")
                if customer_name:
                    print(f"  Customer: {customer_name.content}")
                
                invoice_total = invoice.fields.get("InvoiceTotal")
                if invoice_total:
                    print(f"  Invoice Total: {invoice_total.content}")
                
                invoice_date = invoice.fields.get("InvoiceDate")
                if invoice_date:
                    print(f"  Invoice Date: {invoice_date.content}")


            


    except Exception as ex:
        print(ex)

    print("\nAnalysis complete.\n")

if __name__ == "__main__":
    main()        
