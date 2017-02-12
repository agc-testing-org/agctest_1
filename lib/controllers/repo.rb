# Flow:
# - create repo when people don't have a repo for the project_id
# - provide instructions for how to add a remote to pull the latest changes 
# Answers get merged into 

class Repo   

    def github_client access_code
        begin
            return Octokit::Client.new(:access_token => access_code)
        rescue => e
            puts e
            return nil
        end
    end

   # def get_repository user_id, project_id
   #     begin 
   #         return Contributor.joins(:project).where(:user_id => user_id, :project_id => project_id).last
   #     rescue => e
   #         puts e
   #         return nil
   #     end
   # end

    def get_contributor query
        begin
            return Contributor.where(query).last
        rescue => e
            puts e
            return nil
        end
    end

    def create user_id, project_id, sprint_state_id, repo
        begin
            repo = Contributor.create({
                user_id: user_id,
                project_id: project_id,
                sprint_state_id: sprint_state_id,
                repo: repo
            })
            return repo.id
        rescue => e
            puts e
            return nil
        end
    end

    def refresh session, github_token, contributor_id, sprint_state_id, master_username, master_project, slave_username, slave_project, branch, sha, branch_to_push
        # create branch named after contributor_id
        # push single branch to user repo, using access token

        begin
            if (clear_clone sprint_state_id, contributor_id)
                r = clone "#{ENV['INTEGRATIONS_GITHUB_URL']}/#{master_username}/#{master_project}.git", sprint_state_id, contributor_id, branch
                local_hash = log_head r

                if session
                    account = Account.new
                    github_secret = account.unlock_github_token session, github_token

                    prefix = "https://#{slave_username}:#{github_secret}@github.com"
                else
                    prefix = "https://#{slave_username}:#{ENV['INTEGRATIONS_GITHUB_ADMIN_SECRET']}@github.com"
                end

                if ENV['RACK_ENV'] == "test"
                    prefix = "test"
                end

                added_remote = add_remote r, "#{prefix}/#{slave_username}/#{slave_project}", sprint_state_id

                if added_remote
                    checkout r, sha
                    add_branch r, branch_to_push
                    push_remote r, sprint_state_id, branch_to_push 
                    remote_hash = log_head_remote github_secret, slave_username, slave_project, branch_to_push 
                    clear_clone sprint_state_id, contributor_id
                    return {:success => (remote_hash == local_hash), :sha => remote_hash}
                else
                    return false
                end
            else
                return false
            end
        rescue => e
            puts e
            return false
        end

    end

    def clear_clone sprint_state_id, contributor_id
        directory = "repositories/#{sprint_state_id}_#{contributor_id}"
        FileUtils.rm_rf(directory)
        if File.directory?(directory)
            return false
        else
            return true
        end
    end

    def clone uri, sprint_state_id, contributor_id, branch
        begin
            #g = Git.clone("https://github.com/#{login}/#{name}.git","#{sprint}_#{login}",:path => "repositories")
            return Git.clone(uri,"#{sprint_state_id}_#{contributor_id}",{ :path => "repositories", :branch => branch })
        rescue => e
            puts e
            return nil
        end
    end

    def add_remote g, uri, name
        begin
            #return g.add_remote(resource_id, "https://#{ENV['WIRED7_GITHUB_ADMIN_USER']}:#{ENV['WIRED7_GITHUB_ADMIN_PASSWORD']}@github.com/#{ENV['WIRED7_GITHUB_ADMIN_ORG']}/#{repo}.git")
            return (g.add_remote(name, uri).name == name)
        rescue => e
            puts e
            return false 
        end
    end

    def checkout g, sha
        begin
            return g.checkout(sha)
        rescue => e
            puts e
        end
    end

    def add_branch g, branch
        begin
            return (g.branch(branch.to_s).checkout.include? branch.to_s)
        rescue => e
            puts e
            return false
        end
    end


    def pull_remote g, resource_id
        begin
            g.pull(resource_id.to_s, "master")
            return true
        rescue => e
            puts e
            return nil
        end
    end

    def push_remote g, name, branch
        begin
            g.push(g.remote(name.to_s),branch.to_s,{:force => true})
            return true
        rescue => e
            puts e
            return false
        end
    end

    def log_head r
        begin
            return r.log.first.objectish
        rescue => e
            puts e
            return nil
        end
    end

    def log_head_remote access_code, username, repo, branch 
        github = (github_client access_code)
        if github 
            commit = nil
            poll_count = 0
            while !commit && (poll_count < 10)
                begin
                    commit = github.branch("#{username}/#{repo}", branch)
                rescue => e
                    puts e
                    commit = nil 
                end
                if !commit
                    sleep 3
                    poll_count = poll_count + 1
                end
            end
            return commit.commit.sha
        else
            return nil
        end
    end


    def save_commits resource_id, local, remote, resource_stats
        begin
            repo = Contributor.find_by(id: resource_id)
            repo.commit = local
            repo.commit_remote = remote
            repo.commit_success = (local == remote)
            return repo.save
        rescue => e
            puts e
            return false
        end
    end

    def import token, owner, name, original_owner, original_name
        uri = URI.parse("https://api.github.com/repos/"+owner+"/"+name+"/import")
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        req = Net::HTTP::Put.new(uri.path, initheader = { 
            'Content-Type' => 'application/json',
            'Authorization' => "token #{token}",
            'Accept' => 'application/vnd.github.barred-rock-preview',
            'User-Agent' => 'W7'
        })
        req.body = {
            vcs: "git", 
            vcs_url: "https://github.com/#{original_owner}/#{original_name}.git"
        }.to_json

        begin
            res = https.request(req) 
            return res.code.to_i
        rescue 
            return 500
        end
    end

    def name
        colors = "Nadeshiko-Pink,Napier-Green,Naples-Yellow,Navajo-White,Navy,Navy-Purple,Neon-Carrot,Neon-Fuchsia,Neon-Green,New-Car,New-York-Pink,Nickel,Non-Photo-Blue,North-Texas-Green,Nyanza,Ocean-Blue,Ocean-Boat-Blue,Ocean-Green,Ochre,Office-Green,Ogre-Odor,Old-Burgundy,Old-Gold,Old-Heliotrope,Old-Lace,Old-Lavender,Old-Mauve,Old-Moss-Green,Old-Rose,Old-Silver,Olive,Olivine,Onyx,Opera-Mauve,Orange-Peel,Orange-Soda,Orange-Red,Orange-Yellow,Orchid,Orchid-Pink,Orioles-Orange,Otter-Brown,OU-Crimson-Red,Outer-Space,Outrageous-Orange,Oxford-Blue,Pacific-Blue,Pakistan-Green,Palatinate-Blue,Palatinate-Purple,Pale-Aqua,Pale-Blue,Pale-Brown,Pale-Carmine,Pale-Cerulean,Pale-Chestnut,Pale-Copper,Pale-Cornflower-Blue,Pale-Cyan,Pale-Gold,Pale-Goldenrod,Pale-Green,Pale-Lavender,Pale-Magenta,Pale-Magenta-Pink,Pale-Pink,Pale-Plum,Pale-Red-Violet,Pale-Robin-Egg-Blue,Pale-Silver,Pale-Spring-Bud,Pale-Taupe,Pale-Turquoise,Pale-Violet,Pale-Violet-Red,Palm-Leaf,Pansy-Purple,Paolo-Veronese-Green,Papaya-Whip,Paradise-Pink,Paris-Green,Parrot-Pink,Pastel-Blue,Pastel-Brown,Pastel-Gray,Pastel-Green,Pastel-Magenta,Pastel-Orange,Pastel-Pink,Pastel-Purple,Pastel-Red,Pastel-Violet,Pastel-Yellow,Patriarch,Paynes-Grey,Peach,Peach,Peach-Puff,Peach-Orange,Peach-Yellow,Pear,Pearl,Pearl-Aqua,Pearly-Purple,Peridot,Periwinkle,Permanent-Geranium-Lake,Persian-Blue,Persian-Green,Persian-Indigo,Persian-Orange,Persian-Pink,Persian-Plum,Persian-Red,Persian-Rose,Persimmon,Peru,Pewter-Blue,Phlox,Phthalo-Blue,Phthalo-Green,Picton-Blue,Pictorial-Carmine,Piggy-Pink,Pine-Green,Pineapple,Pink,Pink-Flamingo,Pink-Lace,Pink-Lavender,Pink-Pearl,Pink-Raspberry,Pink-Sherbet,Pink-Orange,Pistachio,Pixie-Powder,Platinum,Plum,Plump-Purple,Polished-Pine,Pomp-And-Power,Popstar,Portland-Orange,Powder-Blue,Princess-Perfume,Princeton-Orange,Prune,Prussian-Blue,Psychedelic-Purple,Puce,Puce-Red,Pullman-Green,Pumpkin,Purple-Heart,Purple-Mountain-Majesty,Purple-Navy,Purple-Pizzazz,Purple-Plum,Purple-Taupe,Purpureus,Quartz,Queen-Blue,Queen-Pink,Quick-Silver,Quinacridone-Magenta,Rackley,Radical-Red,Raisin-Black,Rajah,Raspberry,Raspberry-Glace,Raspberry-Pink,Raspberry-Rose,Raw-Sienna,Raw-Umber,Razzle-Dazzle-Rose,Razzmatazz,Razzmic-Berry,Rebecca-Purple,Red,Red-Devil,Red-Salsa,Red-Brown,Red-Orange,Red-Purple,Red-Violet,Redwood,Regalia,Registration-Black,Resolution-Blue,Rhythm,Rich-Black,Rich-Brilliant-Lavender,Rich-Carmine,Rich-Electric-Blue,Rich-Lavender,Rich-Lilac,Rich-Maroon,Rifle-Green,Roast-Coffee,Robin-Egg-Blue,Rocket-Metallic,Roman-Silver,Rose,Rose-Bonbon,Rose-Dust,Rose-Ebony,Rose-Gold,Rose-Madder,Rose-Pink,Rose-Quartz,Rose-Red,Rose-Taupe,Rose-Vale,Rosewood,Rosso-Corsa,Rosy-Brown,Royal-Azure,Royal-Blue,Royal-Blue,Royal-Fuchsia,Royal-Purple,Royal-Yellow,Ruber,Rubine-Red,Ruby,Ruby-Red,Ruddy,Ruddy-Brown,Ruddy-Pink,Rufous,Russet,Russian-Green,Russian-Violet,Rust,Rusty-Red,Sacramento-State-Green,Saddle-Brown,Safety-Orange,Safety-Yellow,Saffron,Sage,Salmon,Salmon-Pink,Sand,Sand-Dune,Sandstorm,Sandy-Brown,Sandy-Tan,Sandy-Taupe,Sangria,Sap-Green,Sapphire,Sapphire-Blue,Sasquatch-Socks,Satin-Sheen-Gold,Scarlet,Scarlet,Schauss-Pink,School-Bus-Yellow,Screamin-Green,Sea-Blue,Sea-Foam-Green,Sea-Green,Sea-Serpent,Seal-Brown,Seashell,Selective-Yellow,Sepia,Shadow,Shadow-Blue,Shampoo,Shamrock-Green,Sheen-Green,Shimmering-Blush,Shiny-Shamrock,Shocking-Pink,Sienna,Silver,Silver-Chalice,Silver-Lake-Blue,Silver-Pink,Silver-Sand,Sinopia,Sizzling-Red,Sizzling-Sunrise,Skobeloff,Sky-Blue,Sky-Magenta,Slate-Blue,Slate-Gray,Slimy-Green,Smashed-Pumpkin,Smitten,Smoke,Smokey-Topaz,Smoky-Black,Smoky-Topaz,Snow,Soap,Solid-Pink,Sonic-Silver,Space-Cadet,Spanish-Bistre,Spanish-Blue,Spanish-Carmine,Spanish-Crimson,Spanish-Gray,Spanish-Green,Spanish-Orange,Spanish-Pink,Spanish-Red,Spanish-Sky-Blue,Spanish-Violet,Spanish-Viridian,Spartan-Crimson,Spicy-Mix,Spiro-Disco-Ball,Spring-Bud,Spring-Frost,Spring-Green,St.-Patricks-Blue,Star-Command-Blue,Steel-Blue,Steel-Pink,Steel-Teal,Stil-De-Grain-Yellow,Stizza,Stormcloud,Straw,Strawberry,Sugar-Plum,Sunburnt-Cyclops,Sunglow,Sunny,Sunray,Sunset,Sunset-Orange,Super-Pink,Sweet-Brown,Tan,Tangelo,Tangerine,Tangerine-Yellow,Tango-Pink,Tart-Orange,Taupe,Taupe-Gray,Tea-Green,Tea-Rose,Tea-Rose,Teal,Teal-Blue,Teal-Deer,Teal-Green,Telemagenta,Tenné,Terra-Cotta,Thistle,Thulian-Pink,Tickle-Me-Pink,Tiffany-Blue,Tigers-Eye,Timberwolf,Titanium-Yellow,Tomato,Toolbox,Topaz,Tractor-Red,Trolley-Grey,Tropical-Rain-Forest,Tropical-Violet,True-Blue,Tufts-Blue,Tulip,Tumbleweed,Turkish-Rose,Turquoise,Turquoise-Blue,Turquoise-Green,Turquoise-Surf,Turtle-Green,Tuscan,Tuscan-Brown,Tuscan-Red,Tuscan-Tan,Tuscany,Twilight-Lavender,Tyrian-Purple,UA-Blue,UA-Red,Ube,UCLA-Blue,UCLA-Gold,UFO-Green,Ultra-Pink,Ultra-Red,Ultramarine,Ultramarine-Blue,Umber,Unbleached-Silk,United-Nations-Blue,Unmellow-Yellow,UP-Forest-Green,UP-Maroon,Upsdell-Red,Urobilin,USAFA-Blue,USC-Cardinal,USC-Gold,Utah-Crimson,Van-Dyke-Brown,Vanilla,Vanilla-Ice,Vegas-Gold,Venetian-Red,Verdigris,Vermilion,Vermilion,Veronica,Very-Light-Azure,Very-Light-Blue,Very-Light-Malachite-Green,Very-Light-Tangelo,Very-Pale-Orange,Very-Pale-Yellow,Violet,Violet-Blue,Violet-Red,Viridian,Viridian-Green,Vista-Blue,Vivid-Amber,Vivid-Auburn,Vivid-Burgundy,Vivid-Cerise,Vivid-Cerulean,Vivid-Crimson,Vivid-Gamboge,Vivid-Lime-Green,Vivid-Malachite,Vivid-Mulberry,Vivid-Orange,Vivid-Orange-Peel,Vivid-Orchid,Vivid-Raspberry,Vivid-Red,Vivid-Red-Tangelo,Vivid-Sky-Blue,Vivid-Tangelo,Vivid-Tangerine,Vivid-Vermilion,Vivid-Violet,Vivid-Yellow,Volt,Wageningen-Green,Warm-Black,Waterspout,Weldon-Blue,Wenge,Wheat,White,White-Smoke,Wild-Blue-Yonder,Wild-Orchid,Wild-Strawberry,Wild-Watermelon,Willpower-Orange,Windsor-Tan,Wine,Wine-Dregs,Winter-Sky,Winter-Wizard,Wintergreen-Dream,Wisteria,Wood-Brown,Xanadu,Yale-Blue,Yankees-Blue,Yellow,Yellow-Orange,Yellow-Rose,Yellow-Sunshine,Yellow-Green,Zaffre,Zinnwaldite-Brown,Zomp,Absolute-Zero,Acid-Green,Aero,Aero-Blue,African-Violet,Air-Superiority-Blue,Alabama-Crimson,Alabaster,Alice-Blue,Alien-Armpit,Alizarin-Crimson,Alloy-Orange,Almond,Amaranth,Amaranth-Deep-Purple,Amaranth-Pink,Amaranth-Purple,Amaranth-Red,Amazon,Amazonite,Amber,American-Rose,Amethyst,Android-Green,Anti-Flash-White,Antique-Brass,Antique-Bronze,Antique-Fuchsia,Antique-Ruby,Antique-White,Apple-Green,Apricot,Aqua,Aquamarine,Arctic-Lime,Army-Green,Arsenic,Artichoke,Arylide-Yellow,Ash-Grey,Asparagus,Atomic-Tangerine,Auburn,Aureolin,AuroMetalSaurus,Avocado,Awesome,Aztec-Gold,Azure,Azure-Mist,Azureish-White,Baby-Blue,Baby-Blue-Eyes,Baby-Pink,Baby-Powder,Baker-Miller-Pink,Ball-Blue,Banana-Mania,Banana-Yellow,Bangladesh-Green,Barbie-Pink,Barn-Red,Battery-Charged-Blue,Battleship-Grey,Bazaar,Beau-Blue,Beaver,Begonia,Beige,Big-Foot-Feet,Bisque,Bistre,Bistre-Brown,Bitter-Lemon,Bitter-Lime,Bittersweet,Bittersweet-Shimmer,Black,Black-Bean,Black-Coral,Black-Leather-Jacket,Black-Olive,Black-Shadows,Blanched-Almond,Blast-Off-Bronze,Bleu-De-France,Blizzard-Blue,Blond,Blue,Blue-Bell,Blue-Bolt,Blue-Gray,Blue-Green,Blue-Jeans,Blue-Lagoon,Blue-Magenta-Violet,Blue-Sapphire,Blue-Violet,Blue-Yonder,Blueberry,Bluebonnet,Blush,Bole,Bondi-Blue,Bone,Booger-Buster,Bottle-Green,Boysenberry,Brandeis-Blue,Brass,Brick-Red,Bright-Cerulean,Bright-Green,Bright-Lavender,Bright-Lilac,Bright-Maroon,Bright-Navy-Blue,Bright-Pink,Bright-Turquoise,Bright-Ube,Brilliant-Azure,Brilliant-Lavender,Brilliant-Rose,Brink-Pink,British-Racing-Green,Bronze,Bronze-Yellow,Brown-Nose,Brown-Sugar,Brown-Yellow,Brunswick-Green,Bubble-Gum,Bubbles,Bud-Green,Buff,Bulgarian-Rose,Burgundy,Burlywood,Burnished-Brown,Burnt-Orange,Burnt-Sienna,Burnt-Umber,Byzantine,Byzantium,Cadet,Cadet-Blue,Cadet-Grey,Cadmium-Green,Cadmium-Orange,Cadmium-Red,Cadmium-Yellow,Cambridge-Blue,Camel,Cameo-Pink,Camouflage-Green,Canary,Canary-Yellow,Candy-Apple-Red,Candy-Pink,Capri,Caput-Mortuum,Cardinal,Caribbean-Green,Carmine,Carmine-Pink,Carmine-Red,Carnation-Pink,Carnelian,Carolina-Blue,Carrot-Orange,Castleton-Green,Catalina-Blue,Catawba,Cedar-Chest,Ceil,Celadon,Celadon-Blue,Celadon-Green,Celeste,Celestial-Blue,Cerise,Cerise-Pink,Cerulean,Cerulean-Blue,Cerulean-Frost,CG-Blue,CG-Red,Chamoisee,Champagne,Champagne-Pink,Charcoal,Charleston-Green,Charm-Pink,Cherry,Cherry-Blossom-Pink,Chestnut,China-Pink,China-Rose,Chinese-Red,Chinese-Violet,Chlorophyll-Green,Chrome-Yellow,Cinereous,Cinnabar,Cinnamon-Satin,Citrine,Citron,Claret,Classic-Rose,Cobalt-Blue,Cocoa-Brown,Coconut,Coffee,Columbia-Blue,Congo-Pink,Cool-Black,Cool-Grey,Copper,Copper-Penny,Copper-Red,Copper-Rose,Coquelicot,Coral,Coral-Pink,Coral-Red,Coral-Reef,Cordovan,Corn,Cornell-Red,Cornflower-Blue,Cornsilk,Cosmic-Cobalt,Cosmic-Latte,Coyote-Brown,Cotton-Candy,Cream,Crimson,Crimson-Glory,Crimson-Red,Cultured,Cyan,Cyan-Azure,Cyan-Blue-Azure,Cyan-Cobalt-Blue,Cyan-Cornflower-Blue,Cyber-Grape,Cyber-Yellow,Cyclamen,Daffodil,Dandelion,Dark-Blue,Dark-Blue-Gray,Dark-Brown,Dark-Brown-Tangelo,Dark-Byzantium,Dark-Candy-Apple-Red,Dark-Cerulean,Dark-Chestnut,Dark-Coral,Dark-Cyan,Dark-Electric-Blue,Dark-Goldenrod,Dark-Green,Dark-Gunmetal,Dark-Imperial-Blue,Dark-Imperial-Blue,Dark-Jungle-Green,Dark-Khaki,Dark-Lava,Dark-Lavender,Dark-Liver,Dark-Magenta,Dark-Medium-Gray,Dark-Midnight-Blue,Dark-Moss-Green,Dark-Olive-Green,Dark-Orange,Dark-Orchid,Dark-Pastel-Blue,Dark-Pastel-Green,Dark-Pastel-Purple,Dark-Pastel-Red,Dark-Pink,Dark-Powder-Blue,Dark-Puce,Dark-Purple,Dark-Raspberry,Dark-Red,Dark-Salmon,Dark-Scarlet,Dark-Sea-Green,Dark-Sienna,Dark-Sky-Blue,Dark-Slate-Blue,Dark-Slate-Gray,Dark-Spring-Green,Dark-Tan,Dark-Tangerine,Dark-Taupe,Dark-Terra-Cotta,Dark-Turquoise,Dark-Vanilla,Dark-Violet,Dark-Yellow,Dartmouth-Green,Debian-Red,Deep-Aquamarine,Deep-Carmine,Deep-Carmine-Pink,Deep-Carrot-Orange,Deep-Cerise,Deep-Champagne,Deep-Chestnut,Deep-Coffee,Deep-Fuchsia,Deep-Green,Deep-Green-Cyan-Turquoise,Deep-Jungle-Green,Deep-Koamaru,Deep-Lemon,Deep-Lilac,Deep-Magenta,Deep-Maroon,Deep-Mauve,Deep-Moss-Green,Deep-Peach,Deep-Pink,Deep-Puce,Deep-Red,Deep-Ruby,Deep-Saffron,Deep-Sky-Blue,Deep-Space-Sparkle,Deep-Spring-Bud,Deep-Taupe,Deep-Tuscan-Red,Deep-Violet,Deer,Denim,Denim-Blue,Desaturated-Cyan,Desert,Desert-Sand,Desire,Diamond,Dim-Gray,Dingy-Dungeon,Dirt,Dodger-Blue,Dogwood-Rose,Dollar-Bill,Dolphin-Gray,Donkey-Brown,Drab,Duke-Blue,Dust-Storm,Dutch-White,Earth-Yellow,Ebony,Ecru,Eerie-Black,Eggplant,Eggshell,Egyptian-Blue,Electric-Blue,Electric-Crimson,Electric-Cyan,Electric-Green,Electric-Indigo,Electric-Lavender,Electric-Lime,Electric-Purple,Electric-Ultramarine,Electric-Violet,Electric-Yellow,Emerald,Eminence,English-Green,English-Lavender,English-Red,English-Vermillion,English-Violet,Eton-Blue,Eucalyptus,Fallow,Falu-Red,Fandango,Fandango-Pink,Fashion-Fuchsia,Fawn,Feldgrau,Feldspar,Fern-Green,Ferrari-Red,Field-Drab,Fiery-Rose,Firebrick,Fire-Engine-Red,Flame,Flamingo-Pink,Flattery,Flavescent,Flax,Flirt,Floral-White,Fluorescent-Orange,Fluorescent-Pink,Fluorescent-Yellow,Folly,French-Beige,French-Bistre,French-Blue,French-Fuchsia,French-Lilac,French-Lime,French-Mauve,French-Pink,French-Plum,French-Puce,French-Raspberry,French-Rose,French-Sky-Blue,French-Violet,French-Wine,Fresh-Air,Frostbite,Fuchsia,Fuchsia-Pink,Fuchsia-Purple,Fuchsia-Rose,Fulvous,Fuzzy-Wuzzy,Gainsboro,Gamboge,Gargoyle-Gas,Generic-Viridian,Ghost-White,Giants-Club,Giants-Orange,Ginger,Glaucous,Glitter,Glossy-Grape,GO-Green,Gold-Fusion,Golden-Brown,Golden-Poppy,Golden-Yellow,Goldenrod,Granite-Gray,Granny-Smith-Apple,Grape,Gray,Gray-Asparagus,Gray-Blue,Green-Blue,Green-Cyan,Green-Lizard,Green-Sheen,Green-Yellow,Grizzly,Grullo,Guppie-Green,Gunmetal,Han-Blue,Han-Purple,Hansa-Yellow,Harlequin,Harlequin-Green,Harvard-Crimson,Harvest-Gold,Heart-Gold,Heat-Wave,Heliotrope,Heliotrope-Gray,Heliotrope-Magenta,Hollywood-Cerise,Honeydew,Honolulu-Blue,Hot-Magenta,Hot-Pink,Hunter-Green,Iceberg,Icterine,Iguana-Green,Illuminating-Emerald,Imperial,Imperial-Blue,Imperial-Purple,Imperial-Red,Inchworm,Independence,India-Green,Indian-Red,Indian-Yellow,Indigo,Indigo-Dye,Infra-Red,Interdimensional-Blue,Iris,Irresistible,Isabelline,Islamic-Green,Italian-Sky-Blue,Ivory,Jade,Japanese-Carmine,Japanese-Indigo,Japanese-Violet,Jasmine,Jasper,Jazzberry-Jam,Jelly-Bean,Jet,Jonquil,Jordy-Blue,June-Bud,Jungle-Green,Kelly-Green,Kenyan-Copper,Keppel,Key-Lime,Kiwi,Kobe,Kobi,Kobicha,Kombu-Green,KSU-Purple,KU-Crimson,La-Salle-Green,Languid-Lavender,Lapis-Lazuli,Laser-Lemon,Laurel-Green,Lava,Lavender-Blue,Lavender-Blush,Lavender-Gray,Lavender-Indigo,Lavender-Magenta,Lavender-Mist,Lavender-Pink,Lavender-Purple,Lavender-Rose,Lawn-Green,Lemon,Lemon-Chiffon,Lemon-Curry,Lemon-Glacier,Lemon-Lime,Lemon-Meringue,Lemon-Yellow,Licorice,Liberty,Light-Apricot,Light-Blue,Light-Brown,Light-Carmine-Pink,Light-Cobalt-Blue,Light-Coral,Light-Cornflower-Blue,Light-Crimson,Light-Cyan,Light-Deep-Pink,Light-French-Beige,Light-Fuchsia-Pink,Light-Goldenrod-Yellow,Light-Gray,Light-Grayish-Magenta,Light-Green,Light-Hot-Pink,Light-Khaki,Light-Medium-Orchid,Light-Moss-Green,Light-Orchid,Light-Pastel-Purple,Light-Pink,Light-Red-Ochre,Light-Salmon,Light-Salmon-Pink,Light-Sea-Green,Light-Sky-Blue,Light-Slate-Gray,Light-Steel-Blue,Light-Taupe,Light-Thulian-Pink,Light-Yellow,Lilac,Lilac-Luster,Lime-Green,Limerick,Lincoln-Green,Linen,Lion,Liseran-Purple,Little-Boy-Blue,Liver,Liver-Chestnut,Livid,Lumber,Lust,Maastricht-Blue,Macaroni-And-Cheese,Madder-Lake,Magenta,Magenta-Haze,Magenta-Pink,Magic-Mint,Magic-Potion,Magnolia,Mahogany,Maize,Majorelle-Blue,Malachite,Manatee,Mandarin,Mango-Tango,Mantis,Mardi-Gras,Marigold,Mauve,Mauve-Taupe,Mauvelous,Maximum-Blue,Maximum-Blue-Green,Maximum-Blue-Purple,Maximum-Green,Maximum-Green-Yellow,Maximum-Purple,Maximum-Red,Maximum-Red-Purple,Maximum-Yellow,Maximum-Yellow-Red,May-Green,Maya-Blue,Meat-Brown,Medium-Aquamarine,Medium-Blue,Medium-Candy-Apple-Red,Medium-Carmine,Medium-Champagne,Medium-Electric-Blue,Medium-Jungle-Green,Medium-Lavender-Magenta,Medium-Orchid,Medium-Persian-Blue,Medium-Purple,Medium-Red-Violet,Medium-Ruby,Medium-Sea-Green,Medium-Sky-Blue,Medium-Slate-Blue,Medium-Spring-Bud,Medium-Spring-Green,Medium-Taupe,Medium-Turquoise,Medium-Tuscan-Red,Medium-Vermilion,Medium-Violet-Red,Mellow-Apricot,Mellow-Yellow,Melon,Metallic-Seaweed,Metallic-Sunburst,Mexican-Pink,Middle-Blue,Middle-Blue-Green,Middle-Blue-Purple,Middle-Red-Purple,Middle-Green,Middle-Green-Yellow,Middle-Purple,Middle-Red,Middle-Red-Purple,Middle-Yellow,Middle-Yellow-Red,Midnight,Midnight-Blue,Mikado-Yellow,Mimi-Pink,Mindaro,Ming,Minion-Yellow,Mint,Mint-Cream,Mint-Green,Misty-Moss,Misty-Rose,Moccasin,Mode-Beige,Moonstone-Blue,Mordant-Red-19,Moss-Green,Mountain-Meadow,Mountbatten-Pink,MSU-Green,Mughal-Green,Mulberry,Mustard,Myrtle-Green,Mystic,Mystic-Maroon"

                            adjectives = "palatable,pale,paltry,parallel,parched,partial,passionate,past,pastel,peaceful,peppery,perfect,perfumed,periodic,perky,personal,pertinent,pesky,pessimistic,petty,phony,physical,piercing,pink,pitiful,plain,plaintive,plastic,playful,pleasant,pleased,pleasing,plump,plush,polished,polite,political,pointed,pointless,poised,poor,popular,portly,posh,positive,possible,potable,powerful,powerless,practical,precious,present,prestigious,pretty,precious,previous,pricey,prickly,primary,prime,pristine,private,prize,probable,productive,profitable,profuse,proper,proud,prudent,punctual,pungent,puny,pure,purple,pushy,putrid,puzzled,puzzling,sad,safe,salty,same,sandy,sane,sarcastic,sardonic,satisfied,scaly,scarce,scared,scary,scented,scholarly,scientific,scornful,scratchy,scrawny,second,secondary,second-hand,secret,self-assured,self-reliant,selfish,sentimental,separate,serene,serious,serpentine,several,severe,shabby,shadowy,shady,shallow,shameful,shameless,sharp,shimmering,shiny,shocked,shocking,shoddy,short,short-term,showy,shrill,shy,sick,silent,silky,silly,silver,similar,simple,simplistic,sinful,single,sizzling,skeletal,skinny,sleepy,slight,slim,slimy,slippery,slow,slushy,small,smart,smoggy,smooth,smug,snappy,snarling,sneaky,sniveling,snoopy,sociable,soft,soggy,solid,somber,some,spherical,sophisticated,sore,sorrowful,soulful,soupy,sour,Spanish,sparkling,sparse,specific,spectacular,speedy,spicy,spiffy,spirited,spiteful,splendid,spotless,spotted,spry,square,squeaky,squiggly,stable,staid,stained,stale,standard,starchy,stark,starry,steep,sticky,stiff,stimulating,stingy,stormy,straight,strange,steel,strict,strident,striking,striped,strong,studious,stunning,stupendous,stupid,sturdy,stylish,subdued,submissive,substantial,subtle,suburban,sudden,sugary,sunny,super,superb,superficial,superior,supportive,sure-footed,surprised,suspicious,svelte,sweaty,sweet,sweltering,swift,sympathetic,abandoned,able,absolute,adorable,adventurous,academic,acceptable,acclaimed,accomplished,accurate,aching,acidic,acrobatic,active,actual,adept,admirable,admired,adolescent,adorable,adored,advanced,afraid,affectionate,aged,aggravating,aggressive,agile,agitated,agonizing,agreeable,ajar,alarmed,alarming,alert,alienated,alive,all,altruistic,amazing,ambitious,ample,amused,amusing,anchored,ancient,angelic,angry,anguished,animated,annual,another,antique,anxious,any,apprehensive,appropriate,apt,arctic,arid,aromatic,artistic,ashamed,assured,astonishing,athletic,attached,attentive,attractive,austere,authentic,authorized,automatic,avaricious,average,aware,awesome,awful,awkward,babyish,bad,back,baggy,bare,barren,basic,beautiful,belated,beloved,beneficial,better,best,bewitched,big,big-hearted,biodegradable,bite-sized,bitter,black,black-and-white,bland,blank,blaring,bleak,blind,blissful,blond,blue,blushing,bogus,boiling,bold,bony,boring,bossy,both,bouncy,bountiful,bowed,brave,breakable,brief,bright,brilliant,brisk,broken,bronze,brown,bruised,bubbly,bulky,bumpy,buoyant,burdensome,burly,bustling,busy,buttery,buzzing,calculating,calm,candid,canine,capital,carefree,careful,careless,caring,cautious,cavernous,celebrated,charming,cheap,cheerful,cheery,chief,chilly,chubby,circular,classic,clean,clear,clear-cut,clever,close,closed,cloudy,clueless,clumsy,cluttered,coarse,cold,colorful,colorless,colossal,comfortable,common,compassionate,competent,complete,complex,complicated,composed,concerned,concrete,confused,conscious,considerate,constant,content,conventional,cooked,cool,cooperative,coordinated,corny,corrupt,costly,courageous,courteous,crafty,crazy,creamy,creative,creepy,criminal,crisp,critical,crooked,crowded,cruel,crushing,cuddly,cultivated,cultured,cumbersome,curly,curvy,cute,cylindrical,each,eager,earnest,early,easy,easy-going,ecstatic,edible,educated,elaborate,elastic,elated,elderly,electric,elegant,elementary,elliptical,embarrassed,embellished,eminent,emotional,empty,enchanted,enchanting,energetic,enlightened,enormous,enraged,entire,envious,equal,equatorial,essential,esteemed,ethical,euphoric,even,evergreen,everlasting,every,evil,exalted,excellent,exemplary,exhausted,excitable,excited,exciting,exotic,expensive,experienced,expert,extraneous,extroverted,extra-large,extra-small,gargantuan,gaseous,general,generous,gentle,genuine,giant,giddy,gigantic,gifted,giving,glamorous,glaring,glass,gleaming,gleeful,glistening,glittering,gloomy,glorious,glossy,glum,golden,good,good-natured,gorgeous,graceful,gracious,grand,grandiose,granular,grateful,grave,gray,great,greedy,green,gregarious,grim,grimy,gripping,grizzled,gross,grotesque,grouchy,grounded,growing,growling,grown,grubby,gruesome,grumpy,guilty,gullible,gummy,jaded,jagged,jam-packed,jaunty,jealous,jittery,joint,jolly,jovial,joyful,joyous,jubilant,judicious,juicy,jumbo,junior,jumpy,juvenile,tall,talkative,tame,tan,tangible,tart,tasty,tattered,taut,tedious,teeming,tempting,tender,tense,tepid,terrible,terrific,testy,thankful,that,these,thick,thin,third,thirsty,this,thorough,thorny,those,thoughtful,threadbare,thrifty,thunderous,tidy,tight,timely,tinted,tiny,tired,torn,total,tough,traumatic,treasured,tremendous,tragic,trained,tremendous,triangular,tricky,trifling,trim,trivial,troubled,true,trusting,trustworthy,trusty,truthful,tubby,turbulent,twin,vacant,vague,vain,valid,valuable,vapid,variable,vast,velvety,venerated,vengeful,verifiable,vibrant,vicious,victorious,vigilant,vigorous,villainous,violet,violent,virtual,virtuous,visible,vital,vivacious,vivid,voluminous"

                            color_array = colors.split(",")
                            adjective_array = adjectives.split(",")

                            selected_color = color_array[rand(color_array.length)]

                            selected_adjective = adjective_array[rand(adjective_array.length)]

                            final = "#{selected_adjective}-#{selected_color.downcase}-#{rand(10000)}"
                            puts final
                            return final
    end

end
