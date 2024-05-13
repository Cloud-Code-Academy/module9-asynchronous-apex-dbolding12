/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable implements Queueable {

    private static final Integer MAX_JOBS = 5;
    private static final Integer BATCH_SIZE = 10; 
    // Member variable to store the accounts
    private Map<Id,Account> accounts;

    // Constructor to accept the accounts
    public NextStepQueueable(Map<Id,Account> accounts) {
        // Store the accounts in a member variable
        this.accounts = accounts;
    }

    // Method to queue the job
    public static void enqueueJob() {
        System.debug('Enqueue Job');
        // Get 10 accounts with Next Step populated
        Map<Id, Account> updateAccounts = new Map<Id, Account>(
                                                        [SELECT Id, Name, Next_Step__c 
                                                        FROM Account
                                                        WHERE Next_Step__c != Null
                                                        LIMIT :BATCH_SIZE]);

        // If there are any accounts, queue the job using System.enqueueJob
        if (!updateAccounts .isEmpty()) {
            System.debug('Account Size: ' + updateAccounts .size());
            System.enqueueJob(new NextStepQueueable(updateAccounts));

        }
        
    }

    /*
     * Update/Uncomment the template code to create a method
     * Method to execute the queueable job
     */
    public void execute(QueueableContext context) {
        
        Boolean reachedMaxDepth = AsyncInfo.getCurrentQueueableStackDepth() == MAX_JOBS;
        if (!reachedMaxDepth) {        
         // Get the accounts from the member variable
         for (Account acc : this.accounts.values()) {
             // Remove the Next Step using the helper method
            removeNextStep(acc);
         }           

        // Update the accounts
        System.debug(this.accounts.values());
        Database.update(this.accounts.values());

        // Get the opportunities related to the accounts
        List<Opportunity> relatedOpportunities = [SELECT Id, Name, NextStep 
                                                 FROM Opportunity
                                                 WHERE AccountId IN :this.accounts.keySet()];
        
        for (Opportunity opp : relatedOpportunities) {
            // Remove the Next Step using the helper method
            removeNextStep(opp);

        }           

        // Update the opportunities
        System.debug('Updated Opps: ' + relatedOpportunities);
        Database.update(relatedOpportunities);

        // Call the enqueueJob method to queue another job to process more records.
        NextStepQueueable.enqueueJob();

        }
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an opportunity
    private static void removeNextStep(Opportunity opp) {
        opp.NextStep = null;
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an account
    private static void removeNextStep(Account acc) {
        acc.Next_Step__c = null;
    }
}