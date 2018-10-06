App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',

  init: function() {
    return App.initWeb3();
  },

  ///  Configurez web3: web3.js est une bibliothèque javascript qui permet à notre
  ///  application côté client de communiquer avec la blockchain

  initWeb3: function() {
    // TODO: refactor conditional
    if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },

  ///  Initialiser les contrats: nous récupérons l'instance déployée du contrat
  ///  intelligent dans cette fonction et nous attribuons des valeurs qui nous
  ///  permettront d'interagir avec elle

  initContract: function() {
    $.getJSON("MyToken.json", function(election) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.Election = TruffleContract(election);
      // Connect provider to interact with contract
      App.contracts.Election.setProvider(App.web3Provider);

      return App.render();
    });
  },

  ///  Fonction de rendu: la fonction de rendu présente tout le contenu de la
  ///  page avec les données du contrat intelligent.

  render: function() {
    var electionInstance;
    var loader = $("#loader");
    var content = $("#content");

    loader.show();
    content.hide();

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        /// Recuperer l'adresse du compte connté
        App.account = account;
        /// Affiche l'adresse du compte sur la page
        $("#accountAddress").html("Your Account: " + account);
      }
    });

    // Load contract data
    App.contracts.Election.deployed().then(function(instance) {
      /// Recuperer instance du contrat
      electionInstance = instance;

      /// Recuperer le nombre de candidats
      return electionInstance.candidatesCount();

    }).then(function(candidatesCount) {
      var candidatesResults = $("#candidatesResults");
      candidatesResults.empty();

      var candidatesSelect = $('#candidatesSelect');
      candidatesSelect.empty();

      /// Parcourir les candidats
      for (var i = 1; i <= candidatesCount; i++) {
        // Recuperer candidat
        electionInstance.candidates(i).then(function(candidate) {

          // Recuperer infos candidat
          var id = candidate[0];
          var name = candidate[1];
          var voteCount = candidate[2];

          // Render candidate Result
          var candidateTemplate = "<tr><th>" + id + "</th><td>" + name + "</td><td>" + voteCount + "</td></tr>"
          candidatesResults.append(candidateTemplate);

          // Render candidate ballot option
          var candidateOption = "<option value='" + id + "' >" + name + "</ option>"
          candidatesSelect.append(candidateOption);
        });
      }
      return electionInstance.voters(App.account);

    }).then(function(hasVoted) {
      // Do not allow a user to vote
      if(hasVoted) {
        $('form').hide();
      }
      loader.hide();
      content.show();

    }).catch(function(error) {
      console.warn(error);
    });
  },

  castVote: function() {
    var candidateId = $('#candidatesSelect').val();

    App.contracts.Election.deployed().then(function(instance) {
      return instance.vote(candidateId, { from: App.account });

    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();

    }).catch(function(err) {
      console.error(err);
    });
  }

};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
