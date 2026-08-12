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

    sumOrdersOfCurrentAccount;
    hasError = false;

    @wire(getSumOrdersByAccount, { accountId: '$recordId' })
    wiredSumOrders({ data, error }) {
        if (data !== undefined) {
            this.sumOrdersOfCurrentAccount = data;
            this.hasError = !data || data <= 0;
        } else if (error) {
            this.hasError = true;
            this.sumOrdersOfCurrentAccount = undefined;
        }
    }
}
