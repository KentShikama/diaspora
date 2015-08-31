@javascript
Feature: Close account
 In order to close an existing account
 As a user
 I want to sign in, close my account and try to log in again

  Scenario: user closes account
    Given I am signed in
    When I go to the users edit page
    And I click on selector "#close_account"
    Then I should see a modal
