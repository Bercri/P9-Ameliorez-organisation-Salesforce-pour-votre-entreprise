import { LightningElement, api, wire } from 'lwc';
import getSumOrdersByAccount from '@salesforce/apex/MyTeamOrdersController.getSumOrdersByAccount';

/**
 * Composant LWC (anciennement "orders", renommé "accountOrdersSummary").
 *
 * Bug corrigé : la méthode Apex n'était jamais appelée (fetchSumOrders()
 * était vide). Le composant utilise maintenant @wire pour appeler
 * MyTeamOrdersController.getSumOrdersByAccount avec l'Id du compte courant,
 * et bascule l'affichage entre le message d'erreur et le montant total en
 * fonction du résultat.
 */
export default class AccountOrdersSummary extends LightningElement {

    @api recordId;

    sumOrdersOfCurrentAccount; // Montant total affiché dans le template HTML.
    hasError = false; // Bascule l'affichage vers le message d'erreur si vrai.

    // @wire appelle automatiquement la méthode Apex getSumOrdersByAccount
    // dès que recordId est disponible, et ré-exécute l'appel si recordId
    // change (ex: navigation vers un autre compte). '$recordId' avec le $
    // signifie "valeur réactive", pas une chaîne littérale.
    @wire(getSumOrdersByAccount, { accountId: '$recordId' })
    wiredSumOrders({ data, error }) {
        if (data !== undefined) {
            // Appel réussi : on affiche le montant, sauf s'il est nul/à 0
            // (aucune commande Activated pour ce compte).
            this.sumOrdersOfCurrentAccount = data;
            this.hasError = !data || data <= 0;
        } else if (error) {
            // Échec de l'appel Apex (ex: droits insuffisants) : on affiche
            // le message d'erreur plutôt qu'un montant potentiellement faux.
            this.hasError = true;
            this.sumOrdersOfCurrentAccount = undefined;
        }
    }
}
