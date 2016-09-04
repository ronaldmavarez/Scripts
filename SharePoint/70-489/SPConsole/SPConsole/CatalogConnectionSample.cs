using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.SharePoint;
using Microsoft.SharePoint.Publishing;


namespace SPConsole
{
    public class CatalogSubscriber
    {
        string portalSiteUrl;
        string publishingCatalogUrl;
        string subscribingWebServerRelativeUrl;
        /// <summary>
        /// creates a subscription to a catalog from a publishing site.
        /// </summary>
        /// <param name="portalSiteUrl">Absolute Url of the site where a catalog content is rendered</param>
        /// <param name="publishingCatalogUrl">Url of the Library published as a catalog</param>
        /// <param name="subscribingWebServerRelativeUrl">(Optional)Server relative url of a subweb where catalog content is rendered</param>
        public CatalogSubscriber(string publishingCatalogUrl, string portalSiteUrl, string subscribingWebServerRelativeUrl = "/")
        {
            
            if (string.IsNullOrWhiteSpace(portalSiteUrl) ||
                string.IsNullOrWhiteSpace(publishingCatalogUrl))
            {
                throw new ArgumentNullException("A valid url must be provided for publishingCatalogUrl and portalSiteUrl");
            }
            this.portalSiteUrl = portalSiteUrl;
            this.publishingCatalogUrl = publishingCatalogUrl;
            this.subscribingWebServerRelativeUrl = subscribingWebServerRelativeUrl;
        }

        /// <summary>
        /// Connect without any settings
        /// A result source will be created and the catalog will be available for content search webparts
        /// but item urls will have the original path to the source catalog library.
        /// </summary>
        public void ConnectToCatalog()
        {
            using (SPSite publishingPortalSite = new SPSite(this.portalSiteUrl))
            {
                // Get the connection manager for the site where the catalog content will be rendered.
                CatalogConnectionManager manager = new CatalogConnectionManager(publishingPortalSite, createResultSource: true);
                // Use "Contains" to check whether a connection exists.
                if (manager.Contains(this.publishingCatalogUrl))
                {
                    throw new ArgumentException(string.Format("A connection to {0} already exists", this.publishingCatalogUrl));
                }
                // Get the catalog to connect to.
                CatalogConnectionSettings settings = PublishingCatalogUtility.GetPublishingCatalog(publishingPortalSite, this.publishingCatalogUrl);
                settings.ConnectedWebServerRelativeUrl = this.subscribingWebServerRelativeUrl;

                manager.AddCatalogConnection(settings);
                // Perform any other adds/Updates
                // ...
                // Finally commit connection changes to store.
                manager.Update();
            }
        }

        public void ConnectToCatalog(string[] orderedPropertiesForURLRewrite, string taxonomyFieldManagedProperty)
        {

            using (SPSite publishingPortalSite = new SPSite(this.portalSiteUrl))
            {
                // Get the connection manager for the site where the catalog content will be rendered.
                CatalogConnectionManager manager = new CatalogConnectionManager(publishingPortalSite);
                // Use "Contains" to check whether a connection exists.
                if (manager.Contains(this.publishingCatalogUrl))
                {
                    throw new ArgumentException(string.Format("A connection to {0} already exists", this.publishingCatalogUrl));
                }
                // Get the catalog to connect to.
                CatalogConnectionSettings settings = PublishingCatalogUtility.GetPublishingCatalog(publishingPortalSite, this.publishingCatalogUrl);

                manager.AddCatalogConnection(settings,
                    // If the items in the catalog should have rewritten urls, specify what properties should be used in rewriting the url.
                    orderedPropertiesForURLRewrite,
                    this.subscribingWebServerRelativeUrl,
                    // The managed property which contains the category for the catalog item.
                    // Typically starts with owstaxid, when created by the system.
                    taxonomyFieldManagedProperty);
                // Perform any other adds/Updates
                // ...
                // Finally commit connection changes to store.
                manager.Update();
            }
        }

        public void ConnectToCatalog(string newUrlTemplate, string taxonomyFieldManagedProperty, bool isCustomCatalogItemUrlRewriteTemplate)
        {

            using (SPSite publishingPortalSite = new SPSite(this.portalSiteUrl))
            {
                // Get the connection manager for the site where the catalog content will be rendered.
                CatalogConnectionManager manager = new CatalogConnectionManager(publishingPortalSite);
                // Use "Contains" to check whether a connection exists.
                if (manager.Contains(this.publishingCatalogUrl))
                {
                    throw new ArgumentException(string.Format("A connection to {0} already exists", this.publishingCatalogUrl));
                }
                // Get the catalog to connect to.
                CatalogConnectionSettings settings = PublishingCatalogUtility.GetPublishingCatalog(publishingPortalSite, this.publishingCatalogUrl);

                manager.AddCatalogConnection(settings,
                    // If the items in the catalog should have rewritten urls, specify what properties should be used in rewriting the url.
                    newUrlTemplate,
                    this.subscribingWebServerRelativeUrl,
                    // The managed property which contains the category for the catalog item.
                    // Typically starts with owstaxid, when created by the system.
                    taxonomyFieldManagedProperty,
                    isCustomCatalogItemUrlRewriteTemplate);
                // Perform any other adds/Updates
                // ...
                // Finally commit connection changes to store.
                manager.Update();
            }
        }

        /// <summary>
        /// Update the url rewrite template for a catalog connection.
        /// The url rewrite template provides the managed properties from the search schema used to rewrite urls to items from the catalog.
        /// </summary>
        /// <param name="newUrlTemplate"></param>
        public void UpdateCatalogUrlTemplate(string newUrlTemplate)
        {
            using (SPSite publishingPortalSite = new SPSite(this.portalSiteUrl))
            {
                // Get the connection manager for the site where the catalog content will be rendered.
                CatalogConnectionManager manager = new CatalogConnectionManager(publishingPortalSite);
                // Get the current settings
                CatalogConnectionSettings settings = manager.GetCatalogConnectionSettings(this.publishingCatalogUrl);
                if (settings == null)
                {
                    throw new ArgumentException(string.Format("This site is not connected to catalog {0}", this.publishingCatalogUrl));
                }
                settings.CatalogItemUrlRewriteTemplate = newUrlTemplate;
                // Update in memory
                manager.UpdateCatalogConnection(settings);
                // Perform any other adds/Updates

                // Finally Commit the update(s) to store.
                manager.Update();
            }
        }

        public void DeleteCatalog()
        {
            using (SPSite publishingPortalSite = new SPSite(this.portalSiteUrl))
            {
                // Get the connection manager for the site where the catalog content will be rendered.
                CatalogConnectionManager manager = new CatalogConnectionManager(publishingPortalSite);
                // Use "Contains" to check whether a connection exists.
                if (manager.Contains(this.publishingCatalogUrl))
                {
                    // Get the current settings
                    CatalogConnectionSettings settings = manager.GetCatalogConnectionSettings(this.publishingCatalogUrl);

                    manager.DeleteCatalogConnection(this.publishingCatalogUrl);
                    // Perform any other adds/Updates

                    // Finally Commit the update(s) to store.
                    manager.Update();
                }
            }
        }
    }

}
